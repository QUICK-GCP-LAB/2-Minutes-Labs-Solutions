clear

#!/bin/bash
# Define color variables

BLACK=`tput setaf 0`
RED=`tput setaf 1`
GREEN=`tput setaf 2`
YELLOW=`tput setaf 3`
BLUE=`tput setaf 4`
MAGENTA=`tput setaf 5`
CYAN=`tput setaf 6`
WHITE=`tput setaf 7`

BG_BLACK=`tput setab 0`
BG_RED=`tput setab 1`
BG_GREEN=`tput setab 2`
BG_YELLOW=`tput setab 3`
BG_BLUE=`tput setab 4`
BG_MAGENTA=`tput setab 5`
BG_CYAN=`tput setab 6`
BG_WHITE=`tput setab 7`

BOLD=`tput bold`
RESET=`tput sgr0`

# Array of color codes excluding black and white
TEXT_COLORS=($RED $GREEN $YELLOW $BLUE $MAGENTA $CYAN)
BG_COLORS=($BG_RED $BG_GREEN $BG_YELLOW $BG_BLUE $BG_MAGENTA $BG_CYAN)

# Pick random colors
RANDOM_TEXT_COLOR=${TEXT_COLORS[$RANDOM % ${#TEXT_COLORS[@]}]}
RANDOM_BG_COLOR=${BG_COLORS[$RANDOM % ${#BG_COLORS[@]}]}

#----------------------------------------------------start--------------------------------------------------#

echo "${RANDOM_BG_COLOR}${RANDOM_TEXT_COLOR}${BOLD}Starting Execution${RESET}"

# Step 0: Get REGION2 from user input
echo "${BOLD}${CYAN}Getting REGION2 from user${RESET}"
get_and_export_region2() {
  read -p "${BOLD}${CYAN}Please Enter REGION2 : ${RESET}" REGION2
  export REGION2
}

get_and_export_region2

# Step 1: Get project information and set default region/zone
echo "${BOLD}${GREEN}Getting project information and setting default region/zone${RESET}"
export PROJECT_ID=$(gcloud config get-value project)

export PROJECT_NUMBER=$(gcloud projects describe ${PROJECT_ID} \
    --format="value(projectNumber)")

export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")

export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")

# Step 2: Enable required services
echo "${BOLD}${YELLOW}Enabling OS Config API service${RESET}"
gcloud services enable osconfig.googleapis.com

# Step 3: Create firewall rule for health checks
echo "${BOLD}${MAGENTA}Creating firewall rule for health checks${RESET}"
gcloud compute firewall-rules create fw-allow-health-checks \
  --direction=INGRESS \
  --priority=1000 \
  --network=default \
  --action=ALLOW \
  --rules=tcp:80 \
  --source-ranges=130.211.0.0/22,35.191.0.0/16 \
  --target-tags=allow-health-checks

# Step 4: Configure compute region and NAT
echo "${BOLD}${CYAN}Configuring compute region and NAT gateway${RESET}"
gcloud config set compute/region $REGION

gcloud compute routers create nat-router-us1 \
  --network=default \
  --region=$REGION

gcloud compute routers nats create nat-config \
  --router=nat-router-us1 \
  --region=$REGION \
  --auto-allocate-nat-external-ips \
  --nat-all-subnet-ip-ranges

# Step 5: Create webserver instance
echo "${BOLD}${BLUE}Creating webserver instance${RESET}"
gcloud compute instances create webserver \
    --project=$DEVSHELL_PROJECT_ID \
    --zone=$ZONE \
    --machine-type=e2-medium \
    --network-interface=stack-type=IPV4_ONLY,subnet=default,no-address \
    --metadata=enable-osconfig=TRUE,enable-oslogin=true \
    --maintenance-policy=MIGRATE \
    --provisioning-model=STANDARD \
    --service-account=$PROJECT_NUMBER-compute@developer.gserviceaccount.com \
    --scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/trace.append \
    --tags=allow-health-checks \
    --create-disk=boot=yes,device-name=webserver,image=projects/debian-cloud/global/images/debian-12-bookworm-v20250513,mode=rw,size=10,type=pd-balanced \
    --no-shielded-secure-boot \
    --shielded-vtpm \
    --shielded-integrity-monitoring \
    --labels=goog-ops-agent-policy=v2-x86-template-1-4-0,goog-ec-src=vm_add-gcloud \
    --reservation-affinity=any

# Step 6: Configure Ops Agent
echo "${BOLD}${GREEN}Configuring Ops Agent policy${RESET}"
printf 'agentsRule:\n  packageState: installed\n  version: latest\ninstanceFilter:\n  inclusionLabels:\n  - labels:\n      goog-ops-agent-policy: v2-x86-template-1-4-0\n' > config.yaml

# Step 7: Configure snapshot policy
echo "${BOLD}${YELLOW}Configuring disk snapshot policy${RESET}"
gcloud compute instances ops-agents policies create goog-ops-agent-v2-x86-template-1-4-0-$ZONE \
    --project=$DEVSHELL_PROJECT_ID \
    --zone=$ZONE \
    --file=config.yaml

gcloud compute resource-policies create snapshot-schedule default-schedule-1 \
    --project=$DEVSHELL_PROJECT_ID \
    --region=$REGION \
    --max-retention-days=14 \
    --on-source-disk-delete=keep-auto-snapshots \
    --daily-schedule \
    --start-time=16:00

gcloud compute disks add-resource-policies webserver \
    --project=$DEVSHELL_PROJECT_ID \
    --zone=$ZONE \
    --resource-policies=projects/$DEVSHELL_PROJECT_ID/regions/$REGION/resourcePolicies/default-schedule-1

# Step 8: Wait for instance readiness
echo "${BOLD}${MAGENTA}Waiting for instance to be ready${RESET}"
echo
for ((i=30; i>=0; i--)); do
  echo -ne "\r${BOLD}${CYAN}Time remaining${RESET} $i ${BOLD}${CYAN}seconds${RESET}"
  sleep 1
done
echo -e "\n${BOLD}${GREEN}Done!${RESET}"
echo

# Step 9: Install and configure Apache
echo "${BOLD}${BLUE}Installing and configuring Apache web server${RESET}"
gcloud compute ssh webserver --zone=$ZONE --command="sudo apt-get update && sudo apt-get install -y apache2 && sudo service apache2 start && sudo update-rc.d apache2 enable && curl localhost" --quiet

# Step 10: Reset instance
echo "${BOLD}${GREEN}Resetting webserver instance${RESET}"
gcloud compute instances reset webserver --zone=$ZONE

# Step 11: Wait for reset completion
echo "${BOLD}${YELLOW}Waiting for reset to complete${RESET}"
echo
for ((i=30; i>=0; i--)); do
  echo -ne "\r${BOLD}${CYAN}Time remaining${RESET} $i ${BOLD}${CYAN}seconds${RESET}"
  sleep 1
done
echo -e "\n${BOLD}${GREEN}Done!${RESET}"
echo

# Step 12: Verify Apache status
echo "${BOLD}${MAGENTA}Verifying Apache service status${RESET}"
gcloud compute ssh webserver --zone=$ZONE --command="sudo service apache2 status"

# Step 13: Create image from instance
echo "${BOLD}${BLUE}Creating image from webserver instance${RESET}"
gcloud compute instances delete webserver \
  --zone=$ZONE \
  --keep-disks=boot \
  --quiet

gcloud compute images create mywebserver \
  --source-disk=webserver \
  --source-disk-zone=$ZONE \
  --quiet

# Step 14: Create instance template
echo "${BOLD}${GREEN}Creating instance template${RESET}"
gcloud compute instance-templates create mywebserver-template \
  --project=$DEVSHELL_PROJECT_ID \
  --machine-type=e2-micro \
  --network-interface=network=default,stack-type=IPV4_ONLY,no-address \
  --metadata=enable-oslogin=true \
  --maintenance-policy=MIGRATE \
  --provisioning-model=STANDARD \
  --service-account=$PROJECT_NUMBER-compute@developer.gserviceaccount.com \
  --scopes=https://www.googleapis.com/auth/devstorage.read_only,\
https://www.googleapis.com/auth/logging.write,\
https://www.googleapis.com/auth/monitoring.write,\
https://www.googleapis.com/auth/service.management.readonly,\
https://www.googleapis.com/auth/servicecontrol,\
https://www.googleapis.com/auth/trace.append \
  --tags=allow-health-checks \
  --create-disk=auto-delete=yes,boot=yes,device-name=mywebserver-template,\
image=projects/$DEVSHELL_PROJECT_ID/global/images/mywebserver,\
mode=rw,size=10,type=pd-balanced \
  --no-shielded-secure-boot \
  --shielded-vtpm \
  --shielded-integrity-monitoring \
  --reservation-affinity=any \
  --quiet

# Step 15: Create health check
echo "${BOLD}${YELLOW}Creating TCP health check${RESET}"
gcloud compute health-checks create tcp http-health-check \
  --port=80 \
  --quiet

# Step 16: Create managed instance groups
echo "${BOLD}${MAGENTA}Creating managed instance groups${RESET}"
gcloud compute instance-groups managed create us-1-mig \
  --project=$DEVSHELL_PROJECT_ID \
  --base-instance-name=us-1-mig \
  --template=mywebserver-template \
  --region=$REGION \
  --size=1 \
  --target-distribution-shape=EVEN \
  --instance-redistribution-type=PROACTIVE \
  --health-check=http-health-check \
  --initial-delay=60 \
  --quiet

gcloud compute instance-groups managed set-autoscaling us-1-mig \
  --region=$REGION \
  --min-num-replicas=1 \
  --max-num-replicas=2 \
  --target-load-balancing-utilization=0.8 \
  --cool-down-period=60 \
  --mode=on \
  --quiet

gcloud compute instance-groups managed create notus-1-mig \
  --project=$DEVSHELL_PROJECT_ID \
  --base-instance-name=notus-1-mig \
  --template=mywebserver-template \
  --region=$REGION2 \
  --size=1 \
  --target-distribution-shape=EVEN \
  --instance-redistribution-type=PROACTIVE \
  --health-check=http-health-check \
  --initial-delay=60 \
  --quiet

gcloud compute instance-groups managed set-autoscaling notus-1-mig \
  --region=$REGION2 \
  --min-num-replicas=1 \
  --max-num-replicas=2 \
  --target-load-balancing-utilization=0.8 \
  --cool-down-period=60 \
  --mode=on \
  --quiet

echo
for ((i=120; i>=0; i--)); do
  echo -ne "\r${BOLD}${CYAN}Time remaining${RESET} $i ${BOLD}${CYAN}seconds${RESET}"
  sleep 1
done
echo -e "\n${BOLD}${GREEN}Done!${RESET}"
echo

# Step 17: Configure security policy
echo "${BOLD}${BLUE}Configuring security policy${RESET}"
ACCESS_TOKEN=$(gcloud auth print-access-token)

curl -X POST \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  "https://compute.googleapis.com/compute/v1/projects/$PROJECT_ID/global/securityPolicies" \
  -d '{
    "description": "Default security policy for: http-backend",
    "name": "default-security-policy-for-backend-service-http-backend",
    "rules": [
      {
        "action": "allow",
        "match": {
          "config": {
            "srcIpRanges": ["*"]
          },
          "versionedExpr": "SRC_IPS_V1"
        },
        "priority": 2147483647
      },
      {
        "action": "throttle",
        "description": "Default rate limiting rule",
        "match": {
          "config": {
            "srcIpRanges": ["*"]
          },
          "versionedExpr": "SRC_IPS_V1"
        },
        "priority": 2147483646,
        "rateLimitOptions": {
          "conformAction": "allow",
          "enforceOnKey": "IP",
          "exceedAction": "deny(403)",
          "rateLimitThreshold": {
            "count": 500,
            "intervalSec": 60
          }
        }
      }
    ]
  }'

# Step 18: Configure backend service
echo "${BOLD}${GREEN}Configuring backend service${RESET}"
curl -X POST \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  "https://compute.googleapis.com/compute/beta/projects/$PROJECT_ID/global/backendServices" \
  -d '{
    "backends": [
      {
        "balancingMode": "RATE",
        "capacityScaler": 1,
        "group": "projects/'"$PROJECT_ID"'/regions/'"$REGION"'/instanceGroups/us-1-mig",
        "maxRatePerInstance": 50
      },
      {
        "balancingMode": "UTILIZATION",
        "capacityScaler": 1,
        "group": "projects/'"$PROJECT_ID"'/regions/'"$REGION2"'/instanceGroups/notus-1-mig",
        "maxUtilization": 0.79
      }
    ],
    "cdnPolicy": {
      "cacheKeyPolicy": {
        "includeHost": true,
        "includeProtocol": true,
        "includeQueryString": true
      },
      "cacheMode": "CACHE_ALL_STATIC",
      "clientTtl": 3600,
      "defaultTtl": 3600,
      "maxTtl": 86400,
      "negativeCaching": false,
      "serveWhileStale": 0
    },
    "compressionMode": "DISABLED",
    "connectionDraining": {
      "drainingTimeoutSec": 300
    },
    "description": "",
    "enableCDN": true,
    "healthChecks": [
      "projects/'"$PROJECT_ID"'/global/healthChecks/http-health-check"
    ],
    "ipAddressSelectionPolicy": "IPV4_ONLY",
    "loadBalancingScheme": "EXTERNAL_MANAGED",
    "localityLbPolicy": "ROUND_ROBIN",
    "logConfig": {
      "enable": true,
      "sampleRate": 1
    },
    "name": "http-backend",
    "portName": "http",
    "protocol": "HTTP",
    "securityPolicy": "projects/'"$PROJECT_ID"'/global/securityPolicies/default-security-policy-for-backend-service-http-backend",
    "sessionAffinity": "NONE",
    "timeoutSec": 30
  }'

# Step 19: Wait for backend configuration
echo "${BOLD}${YELLOW}Waiting for backend configuration to complete${RESET}"
echo
for ((i=60; i>=0; i--)); do
  echo -ne "\r${BOLD}${CYAN}Time remaining${RESET} $i ${BOLD}${CYAN}seconds${RESET}"
  sleep 1
done
echo -e "\n${BOLD}${GREEN}Done!${RESET}"
echo

# Step 20: Apply security policy to backend
echo "${BOLD}${MAGENTA}Applying security policy to backend service${RESET}"
curl -X POST \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  "https://compute.googleapis.com/compute/v1/projects/$PROJECT_ID/global/backendServices/http-backend/setSecurityPolicy" \
  -d '{
    "securityPolicy": "projects/'"$PROJECT_ID"'/global/securityPolicies/default-security-policy-for-backend-service-http-backend"
  }'

# Step 21: Wait for policy application
echo "${BOLD}${BLUE}Waiting for security policy to be applied${RESET}"
echo
for ((i=60; i>=0; i--)); do
  echo -ne "\r${BOLD}${CYAN}Time remaining${RESET} $i ${BOLD}${CYAN}seconds${RESET}"
  sleep 1
done
echo -e "\n${BOLD}${GREEN}Done!${RESET}"
echo

# Step 22: Configure load balancer components
echo "${BOLD}${GREEN}Configuring load balancer components${RESET}"
curl -X POST \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  "https://compute.googleapis.com/compute/v1/projects/$PROJECT_ID/global/urlMaps" \
  -d '{
    "defaultService": "projects/'"$PROJECT_ID"'/global/backendServices/http-backend",
    "name": "http-lb"
  }'

curl -X POST \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  "https://compute.googleapis.com/compute/v1/projects/$PROJECT_ID/global/targetHttpProxies" \
  -d '{
    "name": "http-lb-target-proxy",
    "urlMap": "projects/'"$PROJECT_ID"'/global/urlMaps/http-lb"
  }'

curl -X POST \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  "https://compute.googleapis.com/compute/beta/projects/$PROJECT_ID/global/forwardingRules" \
  -d '{
    "IPProtocol": "TCP",
    "ipVersion": "IPV4",
    "loadBalancingScheme": "EXTERNAL_MANAGED",
    "name": "http-lb-forwarding-rule",
    "networkTier": "PREMIUM",
    "portRange": "80",
    "target": "projects/'"$PROJECT_ID"'/global/targetHttpProxies/http-lb-target-proxy"
  }'

curl -X POST \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  "https://compute.googleapis.com/compute/v1/projects/$PROJECT_ID/global/targetHttpProxies" \
  -d '{
    "name": "http-lb-target-proxy-2",
    "urlMap": "projects/'"$PROJECT_ID"'/global/urlMaps/http-lb"
  }'

curl -X POST \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  "https://compute.googleapis.com/compute/beta/projects/$PROJECT_ID/global/forwardingRules" \
  -d '{
    "IPProtocol": "TCP",
    "ipVersion": "IPV6",
    "loadBalancingScheme": "EXTERNAL_MANAGED",
    "name": "http-lb-forwarding-rule-2",
    "networkTier": "PREMIUM",
    "portRange": "80",
    "target": "projects/'"$PROJECT_ID"'/global/targetHttpProxies/http-lb-target-proxy-2"
  }'

# Step 23: Configure named ports
echo "${BOLD}${YELLOW}Configuring named ports for instance groups${RESET}"
curl -X POST \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  "https://compute.googleapis.com/compute/beta/projects/$PROJECT_ID/regions/$REGION2/instanceGroups/notus-1-mig/setNamedPorts" \
  -d '{
    "namedPorts": [
      {
        "name": "http",
        "port": 79
      }
    ]
  }'

curl -X POST \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  "https://compute.googleapis.com/compute/beta/projects/$PROJECT_ID/regions/$REGION/instanceGroups/us-1-mig/setNamedPorts" \
  -d '{
    "namedPorts": [
      {
        "name": "http",
        "port": 80
      }
    ]
  }'

# Step 24: Create stress test instance
echo "${BOLD}${MAGENTA}Creating stress test instance${RESET}"
gcloud compute instances create stress-test \
    --project=$DEVSHELL_PROJECT_ID \
    --zone=$ZONE \
    --machine-type=e2-micro \
    --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=default \
    --metadata=enable-osconfig=TRUE,enable-oslogin=true \
    --maintenance-policy=MIGRATE \
    --provisioning-model=STANDARD \
    --service-account=$PROJECT_NUMBER-compute@developer.gserviceaccount.com \
    --scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/trace.append \
    --create-disk=auto-delete=yes,boot=yes,device-name=stress-test,disk-resource-policy=projects/$DEVSHELL_PROJECT_ID/regions/$REGION/resourcePolicies/default-schedule-1,image=projects/$DEVSHELL_PROJECT_ID/global/images/mywebserver,mode=rw,size=10,type=pd-balanced \
    --no-shielded-secure-boot \
    --shielded-vtpm \
    --shielded-integrity-monitoring \
    --labels=goog-ops-agent-policy=v2-x86-template-1-4-0,goog-ec-src=vm_add-gcloud \
    --reservation-affinity=any

echo

# Function to display a random congratulatory message
function random_congrats() {
    MESSAGES=(
        "${GREEN}Congratulations For Completing The Lab! Keep up the great work!${RESET}"
        "${CYAN}Well done! Your hard work and effort have paid off!${RESET}"
        "${YELLOW}Amazing job! You’ve successfully completed the lab!${RESET}"
        "${BLUE}Outstanding! Your dedication has brought you success!${RESET}"
        "${MAGENTA}Great work! You’re one step closer to mastering this!${RESET}"
        "${RED}Fantastic effort! You’ve earned this achievement!${RESET}"
        "${CYAN}Congratulations! Your persistence has paid off brilliantly!${RESET}"
        "${GREEN}Bravo! You’ve completed the lab with flying colors!${RESET}"
        "${YELLOW}Excellent job! Your commitment is inspiring!${RESET}"
        "${BLUE}You did it! Keep striving for more successes like this!${RESET}"
        "${MAGENTA}Kudos! Your hard work has turned into a great accomplishment!${RESET}"
        "${RED}You’ve smashed it! Completing this lab shows your dedication!${RESET}"
        "${CYAN}Impressive work! You’re making great strides!${RESET}"
        "${GREEN}Well done! This is a big step towards mastering the topic!${RESET}"
        "${YELLOW}You nailed it! Every step you took led you to success!${RESET}"
        "${BLUE}Exceptional work! Keep this momentum going!${RESET}"
        "${MAGENTA}Fantastic! You’ve achieved something great today!${RESET}"
        "${RED}Incredible job! Your determination is truly inspiring!${RESET}"
        "${CYAN}Well deserved! Your effort has truly paid off!${RESET}"
        "${GREEN}You’ve got this! Every step was a success!${RESET}"
        "${YELLOW}Nice work! Your focus and effort are shining through!${RESET}"
        "${BLUE}Superb performance! You’re truly making progress!${RESET}"
        "${MAGENTA}Top-notch! Your skill and dedication are paying off!${RESET}"
        "${RED}Mission accomplished! This success is a reflection of your hard work!${RESET}"
        "${CYAN}You crushed it! Keep pushing towards your goals!${RESET}"
        "${GREEN}You did a great job! Stay motivated and keep learning!${RESET}"
        "${YELLOW}Well executed! You’ve made excellent progress today!${RESET}"
        "${BLUE}Remarkable! You’re on your way to becoming an expert!${RESET}"
        "${MAGENTA}Keep it up! Your persistence is showing impressive results!${RESET}"
        "${RED}This is just the beginning! Your hard work will take you far!${RESET}"
        "${CYAN}Terrific work! Your efforts are paying off in a big way!${RESET}"
        "${GREEN}You’ve made it! This achievement is a testament to your effort!${RESET}"
        "${YELLOW}Excellent execution! You’re well on your way to mastering the subject!${RESET}"
        "${BLUE}Wonderful job! Your hard work has definitely paid off!${RESET}"
        "${MAGENTA}You’re amazing! Keep up the awesome work!${RESET}"
        "${RED}What an achievement! Your perseverance is truly admirable!${RESET}"
        "${CYAN}Incredible effort! This is a huge milestone for you!${RESET}"
        "${GREEN}Awesome! You’ve done something incredible today!${RESET}"
        "${YELLOW}Great job! Keep up the excellent work and aim higher!${RESET}"
        "${BLUE}You’ve succeeded! Your dedication is your superpower!${RESET}"
        "${MAGENTA}Congratulations! Your hard work has brought great results!${RESET}"
        "${RED}Fantastic work! You’ve taken a huge leap forward today!${RESET}"
        "${CYAN}You’re on fire! Keep up the great work!${RESET}"
        "${GREEN}Well deserved! Your efforts have led to success!${RESET}"
        "${YELLOW}Incredible! You’ve achieved something special!${RESET}"
        "${BLUE}Outstanding performance! You’re truly excelling!${RESET}"
        "${MAGENTA}Terrific achievement! Keep building on this success!${RESET}"
        "${RED}Bravo! You’ve completed the lab with excellence!${RESET}"
        "${CYAN}Superb job! You’ve shown remarkable focus and effort!${RESET}"
        "${GREEN}Amazing work! You’re making impressive progress!${RESET}"
        "${YELLOW}You nailed it again! Your consistency is paying off!${RESET}"
        "${BLUE}Incredible dedication! Keep pushing forward!${RESET}"
        "${MAGENTA}Excellent work! Your success today is well earned!${RESET}"
        "${RED}You’ve made it! This is a well-deserved victory!${RESET}"
        "${CYAN}Wonderful job! Your passion and hard work are shining through!${RESET}"
        "${GREEN}You’ve done it! Keep up the hard work and success will follow!${RESET}"
        "${YELLOW}Great execution! You’re truly mastering this!${RESET}"
        "${BLUE}Impressive! This is just the beginning of your journey!${RESET}"
        "${MAGENTA}You’ve achieved something great today! Keep it up!${RESET}"
        "${RED}You’ve made remarkable progress! This is just the start!${RESET}"
    )

    RANDOM_INDEX=$((RANDOM % ${#MESSAGES[@]}))
    echo -e "${BOLD}${MESSAGES[$RANDOM_INDEX]}"
}

# Display a random congratulatory message
random_congrats

echo -e "\n"  # Adding one blank line

cd

remove_files() {
    # Loop through all files in the current directory
    for file in *; do
        # Check if the file name starts with "gsp", "arc", or "shell"
        if [[ "$file" == gsp* || "$file" == arc* || "$file" == shell* ]]; then
            # Check if it's a regular file (not a directory)
            if [[ -f "$file" ]]; then
                # Remove the file and echo the file name
                rm "$file"
                echo "File removed: $file"
            fi
        fi
    done
}

remove_files
