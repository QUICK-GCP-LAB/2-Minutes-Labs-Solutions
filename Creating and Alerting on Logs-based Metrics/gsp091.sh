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

# Step 1: Set Project ID, Compute Zone & Region
echo "${BOLD}${GREEN}Setting Project ID, Compute Zone & Region${RESET}"
export PROJECT_ID=$(gcloud info --format='value(config.project)')

export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")

export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")

gcloud config set compute/zone $ZONE

# Step 2: Create Kubernetes Cluster
echo "${BOLD}${CYAN}Creating Kubernetes Cluster${RESET}"
gcloud container clusters create gmp-cluster --num-nodes=1 --zone $ZONE

# Step 3: Create Logging Metric for Stopped VMs
echo "${BOLD}${RED}Creating log-based metric for stopped VMs${RESET}"
gcloud logging metrics create stopped-vm \
    --description="Metric for stopped VMs" \
    --log-filter='resource.type="gce_instance" protoPayload.methodName="v1.compute.instances.stop"'

# Step 4: Create Pub/Sub notification channel config file
echo "${BOLD}${GREEN}Creating Pub/Sub notification channel config file${RESET}"
cat > pubsub-channel.json <<EOF_END
{
  "type": "pubsub",
  "displayName": "awesome",
  "description": "Hiiii There !!",
  "labels": {
    "topic": "projects/$DEVSHELL_PROJECT_ID/topics/notificationTopic"
  }
}
EOF_END

# Step 5: Create the Pub/Sub notification channel
echo "${BOLD}${YELLOW}Creating Pub/Sub notification channel${RESET}"
gcloud beta monitoring channels create --channel-content-from-file=pubsub-channel.json

# Step 6: Retrieve Notification Channel ID
echo "${BOLD}${BLUE}Retrieving Notification Channel ID${RESET}"
email_channel_info=$(gcloud beta monitoring channels list)
email_channel_id=$(echo "$email_channel_info" | grep -oP 'name: \K[^ ]+' | head -n 1)

# Step 7: Create Alert Policy for Stopped VMs
echo "${BOLD}${MAGENTA}Creating alert policy for stopped VMs${RESET}"
cat > stopped-vm-alert-policy.json <<EOF_END
{
  "displayName": "stopped vm",
  "documentation": {
    "content": "Documentation content for the stopped vm alert policy",
    "mime_type": "text/markdown"
  },
  "userLabels": {},
  "conditions": [
    {
      "displayName": "Log match condition",
      "conditionMatchedLog": {
        "filter": "resource.type=\"gce_instance\" protoPayload.methodName=\"v1.compute.instances.stop\""
      }
    }
  ],
  "alertStrategy": {
    "notificationRateLimit": {
      "period": "300s"
    },
    "autoClose": "3600s"
  },
  "combiner": "OR",
  "enabled": true,
  "notificationChannels": [
    "$email_channel_id"
  ]
}


EOF_END

# Step 8: Deploy Alert Policy
echo "${BOLD}${CYAN}Deploying alert policy for stopped VMs${RESET}"
gcloud alpha monitoring policies create --policy-from-file=stopped-vm-alert-policy.json

# Step 9: Create Artifact Registry
echo "${BOLD}${RED}Creating Docker Artifact Registry${RESET}"
gcloud artifacts repositories create docker-repo --repository-format=docker \
    --location=$REGION --description="Docker repository" \
    --project=$DEVSHELL_PROJECT_ID

# Step 10: Download and Load Docker Image
echo "${BOLD}${GREEN}Downloading and loading Docker image${RESET}"
 wget https://storage.googleapis.com/spls/gsp1024/flask_telemetry.zip
 unzip flask_telemetry.zip
 docker load -i flask_telemetry.tar

# Step 11: Tag and Push Docker Image
echo "${BOLD}${YELLOW}Tagging and pushing Docker image${RESET}"
docker tag gcr.io/ops-demo-330920/flask_telemetry:61a2a7aabc7077ef474eb24f4b69faeab47deed9 \
$REGION-docker.pkg.dev/$DEVSHELL_PROJECT_ID/docker-repo/flask-telemetry:v1

docker push $REGION-docker.pkg.dev/$DEVSHELL_PROJECT_ID/docker-repo/flask-telemetry:v1

gcloud container clusters list

# Step 12: Get Cluster Credentials
echo "${BOLD}${BLUE}Getting Kubernetes cluster credentials${RESET}"
gcloud container clusters get-credentials gmp-cluster

# Step 13: Create Namespace
echo "${BOLD}${MAGENTA}Creating Kubernetes namespace${RESET}"
kubectl create ns gmp-test

# Step 14: Download and Unpack Prometheus Setup
echo "${BOLD}${CYAN}Downloading and unpacking Prometheus setup files${RESET}"
wget https://storage.googleapis.com/spls/gsp1024/gmp_prom_setup.zip
unzip gmp_prom_setup.zip
cd gmp_prom_setup

# Step 15: Update Deployment with Docker Image
echo "${BOLD}${RED}Updating deployment manifest with Docker image URL${RESET}"
sed -i "s|<ARTIFACT REGISTRY IMAGE NAME>|$REGION-docker.pkg.dev/$DEVSHELL_PROJECT_ID/docker-repo/flask-telemetry:v1|g" flask_deployment.yaml

# Step 16: Apply Kubernetes Resources
echo "${BOLD}${GREEN}Applying Kubernetes deployment and service${RESET}"
kubectl -n gmp-test apply -f flask_deployment.yaml

kubectl -n gmp-test apply -f flask_service.yaml

# Step 17: Check Services
echo "${BOLD}${YELLOW}Checking Kubernetes services${RESET}"
kubectl get services -n gmp-test

# Step 18: Create Metric for hello-app Errors
echo "${BOLD}${BLUE}Creating log-based metric for hello-app errors${RESET}"
gcloud logging metrics create hello-app-error \
    --description="Metric for hello-app errors" \
    --log-filter='severity=ERROR
resource.labels.container_name="hello-app"
textPayload: "ERROR: 404 Error page not found"'

sleep 30

# Step 19: Create Alert Policy for hello-app Errors
echo "${BOLD}${MAGENTA}Creating alert policy for hello-app errors${RESET}"
cat > awesome.json <<'EOF_END'
{
  "displayName": "log based metric alert",
  "userLabels": {},
  "conditions": [
    {
      "displayName": "New condition",
      "conditionThreshold": {
        "filter": 'metric.type="logging.googleapis.com/user/hello-app-error" AND resource.type="global"',
        "aggregations": [
          {
            "alignmentPeriod": "120s",
            "crossSeriesReducer": "REDUCE_SUM",
            "perSeriesAligner": "ALIGN_DELTA"
          }
        ],
        "comparison": "COMPARISON_GT",
        "duration": "0s",
        "trigger": {
          "count": 1
        }
      }
    }
  ],
  "alertStrategy": {
    "autoClose": "604800s"
  },
  "combiner": "OR",
  "enabled": true,
  "notificationChannels": [],
  "severity": "SEVERITY_UNSPECIFIED"
}

EOF_END

# Step 20: Deploy Alert Policy
echo "${BOLD}${CYAN}Deploying alert policy for hello-app errors${RESET}"
gcloud alpha monitoring policies create --policy-from-file=awesome.json

# Step 21: Trigger Errors
echo "${BOLD}${RED}Triggering errors to generate logs for metric${RESET}"
timeout 120 bash -c -- 'while true; do curl $(kubectl get services -n gmp-test -o jsonpath='{.items[*].status.loadBalancer.ingress[0].ip}')/error; sleep $((RANDOM % 4)) ; done'

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
