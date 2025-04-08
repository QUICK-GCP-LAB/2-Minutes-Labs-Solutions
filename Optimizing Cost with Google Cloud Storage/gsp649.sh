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

# Step 1: Set compute region, project ID & project number
echo "${BOLD}${YELLOW}Setting region, project ID & project number${RESET}"
export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")

export PROJECT_ID=$(gcloud config list --format 'value(core.project)' 2>/dev/null)

export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")

# Step 2: Enable required services
echo "${BOLD}${CYAN}Enabling Cloud Scheduler and Cloud Run APIs${RESET}"
gcloud services enable cloudscheduler.googleapis.com
gcloud services enable run.googleapis.com

# Step 3: Add IAM policy binding for Artifact Registry
echo "${BOLD}${RED}Granting Artifact Registry reader role to Compute Engine default service account${RESET}"
gcloud projects add-iam-policy-binding $PROJECT_ID \
--member="serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com" \
--role="roles/artifactregistry.reader"

# Step 4: Copy training files and move into directory
echo "${BOLD}${GREEN}Copying training files and changing directory${RESET}"
gcloud storage cp -r gs://spls/gsp649/* . && cd gcf-automated-resource-cleanup/
WORKDIR=$(pwd)

# Step 5: Install apache2-utils
echo "${BOLD}${BLUE}Installing apache2-utils${RESET}"
sudo apt-get update
sudo apt-get install apache2-utils -y

# Step 6: Move to migrate-storage directory
echo "${BOLD}${MAGENTA}Moving to migrate-storage directory${RESET}"
cd $WORKDIR/migrate-storage

# Step 7: Create public serving bucket
echo "${BOLD}${CYAN}Creating public serving bucket${RESET}"
gcloud storage buckets create  gs://${PROJECT_ID}-serving-bucket -l $REGION

# Step 8: Make entire bucket publicly readable
echo "${BOLD}${RED}Making serving bucket publicly readable${RESET}"
gsutil acl ch -u allUsers:R gs://${PROJECT_ID}-serving-bucket

# Step 9: Upload test file to serving bucket
echo "${BOLD}${GREEN}Uploading testfile.txt to serving bucket${RESET}"
gcloud storage cp $WORKDIR/migrate-storage/testfile.txt  gs://${PROJECT_ID}-serving-bucket

# Step 10: Make test file publicly accessible
echo "${BOLD}${YELLOW}Making testfile.txt publicly accessible${RESET}"
gsutil acl ch -u allUsers:R gs://${PROJECT_ID}-serving-bucket/testfile.txt

# Step 11: Test file availability via curl
echo "${BOLD}${BLUE}Testing public access to testfile.txt${RESET}"
curl http://storage.googleapis.com/${PROJECT_ID}-serving-bucket/testfile.txt

# Step 12: Create idle bucket
echo "${BOLD}${MAGENTA}Creating idle bucket${RESET}"
gcloud storage buckets create gs://${PROJECT_ID}-idle-bucket -l $REGION
export IDLE_BUCKET_NAME=$PROJECT_ID-idle-bucket

# Step 13: View function call in main.py
echo "${BOLD}${CYAN}Viewing migrate_storage call in main.py${RESET}"
cat $WORKDIR/migrate-storage/main.py | grep "migrate_storage(" -A 15

# Step 14: Replace placeholder with actual project ID
echo "${BOLD}${RED}Replacing <project-id> in main.py${RESET}"
sed -i "s/<project-id>/$PROJECT_ID/" $WORKDIR/migrate-storage/main.py

# Step 15: Disable Cloud Functions temporarily
echo "${BOLD}${GREEN}Disabling Cloud Functions API temporarily${RESET}"
gcloud services disable cloudfunctions.googleapis.com

# Step 16: Wait 10 seconds
echo "${BOLD}${YELLOW}Sleeping for 10 seconds...${RESET}"
sleep 10

# Step 17: Re-enable Cloud Functions
echo "${BOLD}${BLUE}Re-enabling Cloud Functions API${RESET}"
gcloud services enable cloudfunctions.googleapis.com

# Step 18: Deploy the function using Cloud Functions Gen2
echo "${BOLD}${MAGENTA}Deploying Cloud Function (Gen2)${RESET}"
gcloud functions deploy migrate_storage --gen2 --trigger-http --runtime=python39 --region $REGION --allow-unauthenticated

# Step 19: Fetch the function URL
echo "${BOLD}${CYAN}Fetching deployed function URL${RESET}"
export FUNCTION_URL=$(gcloud functions describe migrate_storage --format=json --region $REGION | jq -r '.url')

# Step 20: Replace IDLE_BUCKET_NAME placeholder in incident.json
echo "${BOLD}${RED}Replacing IDLE_BUCKET_NAME placeholder in incident.json${RESET}"
export IDLE_BUCKET_NAME=$PROJECT_ID-idle-bucket
sed -i "s/\\\$IDLE_BUCKET_NAME/$IDLE_BUCKET_NAME/" $WORKDIR/migrate-storage/incident.json

# Step 21: Trigger the function using curl
echo "${BOLD}${GREEN}Triggering function via HTTP request${RESET}"
envsubst < $WORKDIR/migrate-storage/incident.json | curl -X POST -H "Content-Type: application/json" $FUNCTION_URL -d @-

# Step 22: Verify default storage class
echo "${BOLD}${YELLOW}Verifying default storage class for idle bucket${RESET}"
gsutil defstorageclass get gs://$PROJECT_ID-idle-bucket

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