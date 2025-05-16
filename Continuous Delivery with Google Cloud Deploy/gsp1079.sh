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

# Step 1: Set Compute Region
echo "${BOLD}${YELLOW}Setting Compute Region & Zone${RESET}"
export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")

export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")

# Step 2: Get Project ID
echo "${BOLD}${MAGENTA}Getting Project ID${RESET}"
export PROJECT_ID=$(gcloud config get-value project)

# Step 3: Set Gcloud Compute Region
echo "${BOLD}${BLUE}Configuring Gcloud Compute Region${RESET}"
gcloud config set compute/region $REGION

# Step 4: Enable Required Services
echo "${BOLD}${CYAN}Enabling Required Services${RESET}"
gcloud services enable \
container.googleapis.com \
clouddeploy.googleapis.com \
artifactregistry.googleapis.com \
cloudbuild.googleapis.com \
clouddeploy.googleapis.com

# Step 5: Create Clusters
echo "${BOLD}${GREEN}Creating GKE Clusters (test, staging, prod)${RESET}"
gcloud container clusters create test --node-locations=$ZONE --num-nodes=1  --async
gcloud container clusters create staging --node-locations=$ZONE --num-nodes=1  --async
gcloud container clusters create prod --node-locations=$ZONE --num-nodes=1  --async

# Step 6: Create Artifact Registry
echo "${BOLD}${YELLOW}Creating Artifact Registry${RESET}"
gcloud artifacts repositories create web-app \
--description="Image registry for tutorial web app" \
--repository-format=docker \
--location=$REGION

# Step 7: Clone Repository
echo "${BOLD}${MAGENTA}Cloning Repository${RESET}"
cd ~/
git clone https://github.com/GoogleCloudPlatform/cloud-deploy-tutorials.git
cd cloud-deploy-tutorials
git checkout c3cae80 --quiet
cd tutorials/base

# Step 8: Configure Skaffold
echo "${BOLD}${CYAN}Configuring Skaffold${RESET}"
envsubst < clouddeploy-config/skaffold.yaml.template > web/skaffold.yaml
cat web/skaffold.yaml

# Step 9: Create Cloud Build Bucket
echo "${BOLD}${BLUE}Creating Cloud Build Bucket${RESET}"
BUCKET_NAME="${PROJECT_ID}_cloudbuild"

if ! gsutil ls -b "gs://${BUCKET_NAME}" >/dev/null 2>&1; then
  echo "Bucket doesn't exist, Creating bucket"
  gsutil mb -p "$PROJECT_ID" -l "$REGION" "gs://${BUCKET_NAME}"
else
  echo "Bucket gs://${BUCKET_NAME} already exists"
fi

# Step 10: Build Container Images
echo "${BOLD}${GREEN}Building Container Images${RESET}"
cd web
skaffold build --interactive=false \
--default-repo $REGION-docker.pkg.dev/$PROJECT_ID/web-app \
--file-output artifacts.json
cd ..

# Step 11: Deploy Pipeline
echo "${BOLD}${YELLOW}Deploying Pipeline${RESET}"
gcloud artifacts docker images list \
$REGION-docker.pkg.dev/$PROJECT_ID/web-app \
--include-tags \
--format yaml

# Step 12: Deploy Pipeline
echo "${BOLD}${YELLOW}Deploying Pipeline${RESET}"
gcloud config set deploy/region $REGION
cp clouddeploy-config/delivery-pipeline.yaml.template clouddeploy-config/delivery-pipeline.yaml
gcloud beta deploy apply --file=clouddeploy-config/delivery-pipeline.yaml

wait_for_all_clusters_running() {
  echo "${BOLD}${MAGENTA}Waiting for Clusters to be Ready${RESET}"

  while true; do
    CLUSTERS=$(gcloud container clusters list --format="csv[no-heading](name,status)")
    NOT_RUNNING=false

    echo "${BOLD}${CYAN}Checking cluster statuses...${RESET}"
    echo "$CLUSTERS" | while IFS=',' read -r NAME STATUS; do
      if [ "$STATUS" != "RUNNING" ]; then
        echo "${BOLD}${BLUE}Cluster $NAME is $STATUS${RESET}"
        NOT_RUNNING=true
      fi
    done

    NOT_READY=$(echo "$CLUSTERS" | grep -v "RUNNING")

    if [ -z "$NOT_READY" ]; then
      echo "${BOLD}${GREEN}All clusters are running!${RESET}"
      break
    fi

    echo "${BOLD}${RED}Not all clusters are running. Retrying in 1 minute...${RESET}"
    sleep 60
  done
}

wait_for_all_clusters_running

# Step 13: Configure Kubernetes Contexts
echo "${BOLD}${CYAN}Configuring Kubernetes Contexts${RESET}"
CONTEXTS=("test" "staging" "prod")
for CONTEXT in ${CONTEXTS[@]}
do
    gcloud container clusters get-credentials ${CONTEXT} --region ${REGION}
    kubectl config rename-context gke_${PROJECT_ID}_${REGION}_${CONTEXT} ${CONTEXT}
done

# Step 14: Apply Kubernetes Configurations
echo "${BOLD}${BLUE}Applying Kubernetes Configurations${RESET}"
for CONTEXT in ${CONTEXTS[@]}
do
    kubectl --context ${CONTEXT} apply -f kubernetes-config/web-app-namespace.yaml
done

# Step 15: Apply Cloud Deploy Targets
echo "${BOLD}${GREEN}Applying Cloud Deploy Targets${RESET}"
for CONTEXT in ${CONTEXTS[@]}
do
    envsubst < clouddeploy-config/target-$CONTEXT.yaml.template > clouddeploy-config/target-$CONTEXT.yaml
    gcloud beta deploy apply --file clouddeploy-config/target-$CONTEXT.yaml
done

# Step 16: Create Release
echo "${BOLD}${YELLOW}Creating Release${RESET}"
gcloud beta deploy releases create web-app-001 \
--delivery-pipeline web-app \
--build-artifacts web/artifacts.json \
--source web/

# Step 17: List Rollouts
echo "${BOLD}${MAGENTA}Listing Rollouts${RESET}"
gcloud beta deploy rollouts list \
--delivery-pipeline web-app \
--release web-app-001

# Step 18: Promote to Staging
echo "${BOLD}${CYAN}Promoting to Staging${RESET}"
gcloud beta deploy releases promote \
  --delivery-pipeline web-app \
  --release web-app-001 \
  --quiet

# Step 19: Wait for rollout of release 'web-app-001' to target 'staging' to reach state 'SUCCEEDED'...
echo "${BOLD}${BLUE}Waiting for rollout of release 'web-app-001' to target 'staging' to reach state 'SUCCEEDED'...${RESET}"
wait_for_rollout_success() {
  while true; do
    state=$(gcloud beta deploy rollouts list \
      --delivery-pipeline "web-app" \
      --release "web-app-001" \
      --format="value(state)" \
      --filter="targetId=staging")

    echo "${BOLD}${YELLOW}Current rollout state: $state${RESET}"

    if [[ "$state" == "SUCCEEDED" ]]; then
      echo "${BOLD}${GREEN}Rollout succeeded!${RESET}"
      break
    fi

    echo "${BOLD}${RED}Rollout not yet succeeded. Retrying in 15 seconds...${RESET}"
    sleep 15
  done
}

wait_for_rollout_success

# Step 20: Promote to Production
echo "${BOLD}${GREEN}Promoting to Production${RESET}"
gcloud beta deploy releases promote \
--delivery-pipeline web-app \
--release web-app-001 \
--quiet

# Step 21: rollout approve
echo "${BOLD}${YELLOW}Approving Rollout${RESET}"
gcloud beta deploy rollouts approve web-app-001-to-prod-0001 \
--delivery-pipeline web-app \
--release web-app-001 \
--quiet

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