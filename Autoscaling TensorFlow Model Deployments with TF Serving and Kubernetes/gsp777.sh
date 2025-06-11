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

# Step 1: Get default zone and set config
echo "${BOLD}${BLUE}Getting default zone and setting configuration${RESET}"
export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")

# Step 2: Clone the repository
echo "${BOLD}${GREEN}Cloning the MLOps repository${RESET}"
cd
SRC_REPO=https://github.com/GoogleCloudPlatform/mlops-on-gcp
kpt pkg get $SRC_REPO/workshops/mlep-qwiklabs/tfserving-gke-autoscaling tfserving-gke
cd tfserving-gke

# Step 3: Set compute zone
echo "${BOLD}${YELLOW}Setting compute zone to $ZONE${RESET}"
gcloud config set compute/zone $ZONE

# Step 4: Get project ID and set cluster name
echo "${BOLD}${MAGENTA}Configuring project and cluster settings${RESET}"
PROJECT_ID=$(gcloud config get-value project)
CLUSTER_NAME=cluster-1

# Step 5: Create GKE cluster with autoscaling
echo "${BOLD}${CYAN}Creating GKE cluster with autoscaling enabled${RESET}"
gcloud beta container clusters create $CLUSTER_NAME \
  --cluster-version=latest \
  --machine-type=e2-standard-4 \
  --enable-autoscaling \
  --min-nodes=1 \
  --max-nodes=3 \
  --num-nodes=1 

# Step 6: Get cluster credentials
echo "${BOLD}${BLUE}Getting credentials for cluster $CLUSTER_NAME${RESET}"
gcloud container clusters get-credentials $CLUSTER_NAME 

# Step 7: Create model bucket
echo "${BOLD}${GREEN}Creating Cloud Storage bucket for models${RESET}"
export MODEL_BUCKET=${PROJECT_ID}-bucket
gsutil mb gs://${MODEL_BUCKET}

# Step 8: Copy model files
echo "${BOLD}${YELLOW}Copying ResNet model to bucket${RESET}"
gsutil cp -r gs://spls/gsp777/resnet_101 gs://${MODEL_BUCKET}

# Step 9: Update configmap with bucket name
echo "${BOLD}${MAGENTA}Updating configmap with bucket name${RESET}"
echo $MODEL_BUCKET
sed -i "s/your-bucket-name/$MODEL_BUCKET/g" tf-serving/configmap.yaml

# Step 10: Apply Kubernetes configmap
echo "${BOLD}${CYAN}Applying Kubernetes configmap${RESET}"
kubectl apply -f tf-serving/configmap.yaml

# Step 11: Apply Kubernetes deployment
echo "${BOLD}${BLUE}Applying Kubernetes deployment${RESET}"
kubectl apply -f tf-serving/deployment.yaml

# Step 12: Function to wait for deployments to be ready
echo "${BOLD}${CYAN}Waiting for deployments to be ready...${RESET}"
wait_for_deployments_ready() {
  local timeout=120
  local elapsed=0

  while true; do
    not_ready_count=0

    # Get READY field for image-classifier
    line=$(kubectl get deployment image-classifier --no-headers 2>/dev/null)
    
    if [[ -z "$line" ]]; then
      echo "${BOLD}${RED}Deployment 'image-classifier' not found.${RESET}"
      return 1
    fi

    name=$(echo "$line" | awk '{print $1}')
    ready=$(echo "$line" | awk '{print $2}')
    ready_pods=$(echo "$ready" | cut -d'/' -f1)
    total_pods=$(echo "$ready" | cut -d'/' -f2)

    if [[ "$ready_pods" != "$total_pods" ]]; then
      echo "${BOLD}${RED}Deployment '$name' is NOT ready: ${RESET}$ready"
      ((not_ready_count++))
    else
      echo "${BOLD}${GREEN}Deployment '$name' is ready: ${RESET}$ready"
    fi

    if [[ "$not_ready_count" -eq 0 ]]; then
      echo "${BOLD}${YELLOW}image-classifier is READY!${RESET}"
      break
    elif [[ "$elapsed" -ge "$timeout" ]]; then
      echo "${BOLD}${RED}image-classifier not ready after $timeout seconds. Recreating...${RESET}"
      kubectl delete deployment image-classifier
      kubectl apply -f tf-serving/deployment.yaml
      elapsed=0  # Reset timer after reapply
      echo "${BOLD}${GREEN}Re-applied image-classifier. Waiting again...${RESET}"
    else
      echo "${BOLD}${MAGENTA}Waiting 60 seconds before checking again...${RESET}"

      for ((i=60; i>=0; i--)); do
        remaining=$((timeout - elapsed - (60 - i)))
        [[ "$remaining" -lt 0 ]] && remaining=0
        echo -ne "\r${BOLD}${CYAN}Time remaining until recreate: ${RESET}"$remaining "${BOLD}${CYAN}seconds...${RESET} "
        sleep 1
      done
      echo
      ((elapsed+=60))
      echo -e "\n${BOLD}${GREEN}Checking again...${RESET}\n"
    fi
  done
}

# Step 13: Wait for deployment to be ready
echo "${BOLD}${YELLOW}Waiting for image-classifier deployment to be ready...${RESET}"
wait_for_deployments_ready


# Step 14: Apply Kubernetes service
echo "${BOLD}${MAGENTA}Applying Kubernetes service${RESET}"
kubectl apply -f tf-serving/service.yaml

function wait_for_loadbalancer_ip() {
    local service_name=$1
    local namespace=${2:-default}  # optional namespace parameter
    local timeout=${3:-300}       # timeout in seconds (default 5 minutes)
    local interval=${4:-5}        # check interval in seconds (default 5)

    echo "${BOLD}${CYAN}Waiting for external IP for service $service_name in namespace $namespace...${RESET}"
    
    local start_time=$(date +%s)
    local end_time=$((start_time + timeout))
    
    while true; do
        local current_time=$(date +%s)
        if [ $current_time -ge $end_time ]; then
            echo "${BOLD}${RED}Timeout reached. Service did not get an external IP.${RESET}"
            kubectl describe svc "$service_name" -n "$namespace"
            return 1
        fi
        
        # Get the external IP
        local external_ip=$(kubectl get svc "$service_name" -n "$namespace" -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
        
        if [ -n "$external_ip" ]; then
            echo "${BOLD}${GREEN}Service $service_name got external IP: $external_ip${RESET}"
            kubectl get svc "$service_name" -n "$namespace"
            return 0
        fi
        
        # Print current status
        echo -n "."
        sleep "$interval"
    done
}

# Step 15: Wait for load balancer IP
echo "${BOLD}${BLUE}Waiting for load balancer IP to be assigned${RESET}"
wait_for_loadbalancer_ip "image-classifier"

# Step 16: Configure autoscaling for deployment
echo "${BOLD}${YELLOW}Configuring autoscaling for image-classifier deployment${RESET}"
kubectl autoscale deployment image-classifier \
--cpu-percent=60 \
--min=1 \
--max=4 

# Step 17: Get external IP
echo "${BOLD}${MAGENTA}Getting external IP for the service${RESET}"
EXTERNAL_IP=$(kubectl get svc image-classifier -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Step 18: Test prediction endpoint
echo "${BOLD}${CYAN}Testing prediction endpoint${RESET}"
curl -d @locust/request-body.json -H "Content-Type: application/json" \
     -X POST http://${EXTERNAL_IP}:8501/v1/models/image_classifier:predict

# Step 19: Install Locust
echo "${BOLD}${BLUE}Installing Locust for load testing${RESET}"
pip3 install locust==1.4.1

# Step 20: Update PATH
echo "${BOLD}${GREEN}Updating PATH for Locust${RESET}"
export PATH=~/.local/bin:$PATH

# Step 21: Verify Locust version
echo "${BOLD}${YELLOW}Verifying Locust version${RESET}"
locust -V

# Step 22: Run Locust load test
echo "${BOLD}${MAGENTA}Running Locust load test${RESET}"
cd locust
locust -f tasks.py \
--headless \
--host http://${EXTERNAL_IP}:8501

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