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

# Step 1: Set Compute Zone & Region
echo "${BOLD}${BLUE}Setting Compute Zone & Region${RESET}"
set_region_and_zone() {
  echo
  read -p "$(echo -e "${BOLD}${CYAN}Enter a Compute Engine region (e.g., us-central1): ${RESET}")" region_input
  echo
  read -p "$(echo -e "${BOLD}${CYAN}Enter a Compute Engine zone (e.g., us-central-b): ${RESET}")" zone_input
  echo

  export REGION_2="$region_input"
  export ZONE="$zone_input"
  export REGION_3=$(echo "$ZONE" | cut -d '-' -f 1-2)

  echo "${BOLD}${GREEN}$REGION_2 & $ZONE set successfully${RESET}"
  echo
}

set_region_and_zone

# Step 2: Get Default Region from Metadata
echo "${BOLD}${BLUE}Fetching default region from project metadata${RESET}"
export REGION_1=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")


# Step 3: Get Project ID & Project Number
echo "${BOLD}${YELLOW}Fetching project ID and project number${RESET}"
export PROJECT_ID=$(gcloud config get-value project)

export PROJECT_NUMBER=$(gcloud projects describe ${PROJECT_ID} \
    --format="value(projectNumber)")

# Step 4: Enable OS Config API
echo "${BOLD}${CYAN}Enabling OS Config API${RESET}"
gcloud services enable osconfig.googleapis.com

# Step 5: Create firewall rule to allow HTTP
echo "${BOLD}${BLUE}Creating firewall rule allow HTTP${RESET}"
gcloud compute --project=$PROJECT_ID firewall-rules create default-allow-http \
  --direction=INGRESS \
  --priority=1000 \
  --network=default \
  --action=ALLOW \
  --rules=tcp:80 \
  --source-ranges=0.0.0.0/0 \
  --target-tags=http-server

# Step 6: Create firewall rule to allow Health Checks
echo "${BOLD}${RED}Creating firewall rule allow health checks${RESET}"
gcloud compute --project=$PROJECT_ID firewall-rules create default-allow-health-check \
  --direction=INGRESS \
  --priority=1000 \
  --network=default \
  --action=ALLOW \
  --rules=tcp:80 \
  --source-ranges=130.211.0.0/22,35.191.0.0/16 \
  --target-tags=http-server

# Step 7: Create Instance Template in REGION_1
echo "${BOLD}${GREEN}Creating instance template in $REGION_1${RESET}"
gcloud compute instance-templates create $REGION_1-template \
    --region=$REGION_1 \
    --machine-type=e2-standard-2 \
    --network=default \
    --subnet=default \
    --tags=http-server \
    --metadata=startup-script-url=gs://cloud-training/gcpnet/httplb/startup.sh

# Step 8: Create Instance Template in REGION_2
echo "${BOLD}${YELLOW}Creating instance template in $REGION_2${RESET}"
gcloud compute instance-templates create $REGION_2-template \
    --region=$REGION_2 \
    --machine-type=e2-standard-2 \
    --network=default \
    --subnet=default \
    --tags=http-server \
    --metadata=startup-script-url=gs://cloud-training/gcpnet/httplb/startup.sh

# Step 9: Create Managed Instance Group in REGION_1
echo "${BOLD}${MAGENTA}Creating managed instance group in $REGION_1${RESET}"
gcloud compute instance-groups managed create $REGION_1-mig \
    --region=$REGION_1 \
    --template=$REGION_1-template \
    --size=1

# Step 10: Set Autoscaling for REGION_1 MIG
echo "${BOLD}${CYAN}Setting autoscaling for $REGION_1-mig${RESET}"
gcloud compute instance-groups managed set-autoscaling $REGION_1-mig \
    --region=$REGION_1 \
    --min-num-replicas=1 \
    --max-num-replicas=5 \
    --target-cpu-utilization=0.8 \
    --cool-down-period=45

# Step 11: Create Managed Instance Group in REGION_2
echo "${BOLD}${BLUE}Creating managed instance group in $REGION_2${RESET}"
gcloud compute instance-groups managed create $REGION_2-mig \
    --region=$REGION_2 \
    --template=$REGION_2-template \
    --size=1

# Step 12: Set Autoscaling for REGION_2 MIG
echo "${BOLD}${RED}Setting autoscaling for $REGION_2-mig${RESET}"
gcloud compute instance-groups managed set-autoscaling $REGION_2-mig \
    --region=$REGION_2 \
    --min-num-replicas=1 \
    --max-num-replicas=5 \
    --target-cpu-utilization=0.8 \
    --cool-down-period=45

# Step 13: Create TCP Health Check
echo "${BOLD}${GREEN}Creating TCP health check for load balancer${RESET}"
gcloud compute health-checks create tcp http-health-check \
    --port=80 \
    --enable-logging \
    --check-interval=5 \
    --timeout=5 \
    --unhealthy-threshold=2 \
    --healthy-threshold=2

# Step 14: Get access token
echo "${BOLD}${RED}Fetching access token${RESET}"
ACCESS_TOKEN="$(gcloud auth print-access-token)"

# Step 15: Create security policy for backend service
echo "${BOLD}${GREEN}Creating security policy for backend service${RESET}"
curl -X POST \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
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
  }' \
  "https://compute.googleapis.com/compute/v1/projects/$PROJECT_ID/global/securityPolicies"

# Step 16: Create backend service
echo "${BOLD}${YELLOW}Creating backend service with instance groups and health check${RESET}"
curl -X POST \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "backends": [
      {
        "balancingMode": "RATE",
        "capacityScaler": 1,
        "group": "projects/'$PROJECT_ID'/regions/'$REGION_1'/instanceGroups/'$REGION_1'-mig",
        "maxRatePerInstance": 50
      },
      {
        "balancingMode": "UTILIZATION",
        "capacityScaler": 1,
        "group": "projects/'$PROJECT_ID'/regions/'$REGION_2'/instanceGroups/'$REGION_2'-mig",
        "maxUtilization": 0.8
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
    "healthChecks": [
      "projects/'$PROJECT_ID'/global/healthChecks/http-health-check"
    ],
    "loadBalancingScheme": "EXTERNAL_MANAGED",
    "localityLbPolicy": "ROUND_ROBIN",
    "logConfig": {
      "enable": true,
      "sampleRate": 1
    },
    "name": "http-backend",
    "portName": "http",
    "protocol": "HTTP",
    "securityPolicy": "projects/'$PROJECT_ID'/global/securityPolicies/default-security-policy-for-backend-service-http-backend",
    "timeoutSec": 30
  }' \
  "https://compute.googleapis.com/compute/beta/projects/$PROJECT_ID/global/backendServices"

# Step 17: Wait for backend service to be ready
echo "${BOLD}${MAGENTA}Waiting 60 seconds for backend service propagation${RESET}"
for ((i=60; i>=0; i--)); do
  echo -ne "\r${BOLD}${CYAN}Time remaining $i seconds${RESET}"
  sleep 1
done
echo -e "\n${BOLD}${GREEN}Done!${RESET}"
echo

# Step 18: Create URL map
echo "${BOLD}${CYAN}Creating URL map for the load balancer${RESET}"
curl -X POST \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "defaultService": "projects/'$PROJECT_ID'/global/backendServices/http-backend",
    "name": "http-lb"
  }' \
  "https://compute.googleapis.com/compute/v1/projects/$PROJECT_ID/global/urlMaps"

# Step 19: Wait for url map to be ready
echo "${BOLD}${MAGENTA}Waiting 30 seconds for URL map propagation${RESET}"
for ((i=30; i>=0; i--)); do
  echo -ne "\r${BOLD}${CYAN}Time remaining $i seconds${RESET}"
  sleep 1
done
echo -e "\n${BOLD}${GREEN}Done!${RESET}"
echo

# Step 19: Create target HTTP proxy
echo "${BOLD}${BLUE}Creating target HTTP proxy${RESET}"
curl -X POST \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "http-lb-target-proxy",
    "urlMap": "projects/'$PROJECT_ID'/global/urlMaps/http-lb"
  }' \
  "https://compute.googleapis.com/compute/v1/projects/$PROJECT_ID/global/targetHttpProxies"

# Step 20: Create IPv4 forwarding rule
echo "${BOLD}${RED}Creating IPv4 forwarding rule${RESET}"
curl -X POST \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "IPProtocol": "TCP",
    "ipVersion": "IPV4",
    "loadBalancingScheme": "EXTERNAL_MANAGED",
    "name": "http-lb-forwarding-rule",
    "networkTier": "PREMIUM",
    "portRange": "80",
    "target": "projects/'$PROJECT_ID'/global/targetHttpProxies/http-lb-target-proxy"
  }' \
  "https://compute.googleapis.com/compute/beta/projects/$PROJECT_ID/global/forwardingRules"

# Step 21: Create IPv6 forwarding rule
echo "${BOLD}${GREEN}Creating IPv6 forwarding rule${RESET}"
curl -X POST \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "IPProtocol": "TCP",
    "ipVersion": "IPV6",
    "loadBalancingScheme": "EXTERNAL_MANAGED",
    "name": "http-lb-forwarding-rule-2",
    "networkTier": "PREMIUM",
    "portRange": "80",
    "target": "projects/'$PROJECT_ID'/global/targetHttpProxies/http-lb-target-proxy"
  }' \
  "https://compute.googleapis.com/compute/beta/projects/$PROJECT_ID/global/forwardingRules"

# Step 22: Set named port on REGION_1 MIG
echo "${BOLD}${YELLOW}Setting named port on $REGION_1-mig${RESET}"
curl -X POST \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "namedPorts": [
      {
        "name": "http",
        "port": 80
      }
    ]
  }' \
  "https://compute.googleapis.com/compute/beta/projects/$PROJECT_ID/regions/$REGION_1/instanceGroups/$REGION_1-mig/setNamedPorts"

# Step 23: Set named port on REGION_2 MIG
echo "${BOLD}${MAGENTA}Setting named port on $REGION_2-mig${RESET}"
curl -X POST \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "namedPorts": [
      {
        "name": "http",
        "port": 80
      }
    ]
  }' \
  "https://compute.googleapis.com/compute/beta/projects/$PROJECT_ID/regions/$REGION_2/instanceGroups/$REGION_2-mig/setNamedPorts"

# Step 24: Create siege VM instance
echo "${BOLD}${CYAN}Creating siege-vm instance${RESET}"
gcloud compute instances create siege-vm \
    --project=$PROJECT_ID \
    --zone=$ZONE \
    --machine-type=e2-medium \
    --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=default \
    --metadata=enable-osconfig=TRUE,enable-oslogin=true \
    --maintenance-policy=MIGRATE \
    --provisioning-model=STANDARD \
    --service-account=$PROJECT_NUMBER-compute@developer.gserviceaccount.com \
    --scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/trace.append \
    --create-disk=auto-delete=yes,boot=yes,device-name=siege-vm,image=projects/debian-cloud/global/images/debian-12-bookworm-v20250513,mode=rw,size=10,type=pd-balanced \
    --no-shielded-secure-boot \
    --shielded-vtpm \
    --shielded-integrity-monitoring \
    --labels=goog-ops-agent-policy=v2-x86-template-1-4-0,goog-ec-src=vm_add-gcloud \
    --reservation-affinity=any

# Step 25: Create Ops Agent config file
echo "${BOLD}${BLUE}Creating config.yaml for Ops Agent policy${RESET}"
printf 'agentsRule:\n  packageState: installed\n  version: latest\ninstanceFilter:\n  inclusionLabels:\n  - labels:\n      goog-ops-agent-policy: v2-x86-template-1-4-0\n' > config.yaml

# Step 26: Apply Ops Agent policy to siege-vm
echo "${BOLD}${RED}Applying Ops Agent policy to siege-vm${RESET}"
gcloud compute instances ops-agents policies create goog-ops-agent-v2-x86-template-1-4-0-$ZONE \
    --project=$PROJECT_ID \
    --zone=$ZONE \
    --file=config.yaml

# Step 27: Create snapshot schedule policy
echo "${BOLD}${GREEN}Creating daily snapshot schedule policy${RESET}"
gcloud compute resource-policies create snapshot-schedule default-schedule-1 \
    --project=$PROJECT_ID \
    --region=$REGION_3 \
    --max-retention-days=14 \
    --on-source-disk-delete=keep-auto-snapshots \
    --daily-schedule \
    --start-time=06:00

# Step 28: Attach snapshot policy to siege-vm disk
echo "${BOLD}${YELLOW}Attaching snapshot policy to siege-vm disk${RESET}"
gcloud compute disks add-resource-policies siege-vm \
    --project=$PROJECT_ID \
    --zone=$ZONE \
    --resource-policies=projects/$PROJECT_ID/regions/$REGION_3/resourcePolicies/default-schedule-1

# Step 29: Wait for siege-vm to be ready
echo "${BOLD}${MAGENTA}Waiting 30 seconds before SSH into siege-vm${RESET}"
for ((i=30; i>=0; i--)); do
  echo -ne "\r${BOLD}${CYAN}Time remaining $i seconds${RESET}"
  sleep 1
done
echo -e "\n${BOLD}${GREEN}Done!${RESET}"
echo

# Step 30: SSH into siege-vm and install Siege tool
echo "${BOLD}${CYAN}Installing Siege tool on siege-vm${RESET}"
gcloud compute ssh siege-vm \
  --zone=$ZONE \
  --project=$PROJECT_ID \
  --quiet \
  --command="sudo apt-get update -qq && sudo apt-get -y install siege -qq"

# Step 31: Create rate-limiting security policy
echo "${BOLD}${BLUE}Creating security policy rate-limit-siege${RESET}"
gcloud compute security-policies create rate-limit-siege \
    --description "policy for rate limiting"

# Step 32: Add rate-based ban rule to security policy
echo "${BOLD}${RED}Adding rate-based rule to rate-limit-siege policy${RESET}"
gcloud beta compute security-policies rules create 100 \
    --security-policy=rate-limit-siege     \
    --expression="true" \
    --action=rate-based-ban                   \
    --rate-limit-threshold-count=50           \
    --rate-limit-threshold-interval-sec=120   \
    --ban-duration-sec=300           \
    --conform-action=allow           \
    --exceed-action=deny-404         \
    --enforce-on-key=IP

# Step 33: Attach rate-limit-siege policy to backend service
echo "${BOLD}${GREEN}Attaching rate-limit-siege policy to http-backend service${RESET}"
gcloud compute backend-services update http-backend \
    --security-policy rate-limit-siege --global

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