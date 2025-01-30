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

# Step 1: Set ZONE and REGION variables
echo "${BOLD}${YELLOW}Setting compute zone and region variables...${RESET}"
export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")

export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")

# Step 2: Set compute region
echo "${BOLD}${BLUE}Configuring compute region...${RESET}"
gcloud config set compute/region $REGION

# Step 3: Enable Cloud Scheduler API
echo "${BOLD}${MAGENTA}Enabling Cloud Scheduler API...${RESET}"
gcloud services enable cloudscheduler.googleapis.com

# Step 4: Copy required files and navigate to the working directory
echo "${BOLD}${CYAN}Copying required files and changing to the working directory...${RESET}"
gsutil cp -r gs://spls/gsp648 . && cd gsp648

export PROJECT_ID=$(gcloud config list --format 'value(core.project)' 2>/dev/null)
WORKDIR=$(pwd)
cd $WORKDIR/unattached-pd

# Step 5: Modify main.py with project ID
echo "${BOLD}${RED}Updating main.py with the project ID...${RESET}"
sed -i "s/'automating-cost-optimization'/'$(echo $DEVSHELL_PROJECT_ID)'/" main.py

# Step 6: Define orphaned and unused disk names
echo "${BOLD}${GREEN}Setting disk names...${RESET}"
export ORPHANED_DISK=orphaned-disk
export UNUSED_DISK=unused-disk

# Step 7: Create orphaned and unused disks
echo "${BOLD}${YELLOW}Creating orphaned and unused disks...${RESET}"
gcloud compute disks create $ORPHANED_DISK --project=$PROJECT_ID --type=pd-standard --size=500GB --zone=$ZONE

gcloud compute disks create $UNUSED_DISK --project=$PROJECT_ID --type=pd-standard --size=500GB --zone=$ZONE

# Step 8: List all disks
echo "${BOLD}${BLUE}Listing all disks...${RESET}"
gcloud compute disks list

# Step 9: Create an instance and attach the orphaned disk
echo "${BOLD}${MAGENTA}Creating an instance and attaching the orphaned disk...${RESET}"
gcloud compute instances create disk-instance \
--zone=$ZONE \
--machine-type=e2-medium \
--disk=name=$ORPHANED_DISK,device-name=$ORPHANED_DISK,mode=rw,boot=no

# Step 10: Describe the orphaned disk
echo "${BOLD}${CYAN}Describing the orphaned disk...${RESET}"
gcloud compute disks describe $ORPHANED_DISK --zone=$ZONE --format=json | jq

# Function to prompt user to check their progress
function check_progress {
    while true; do
        echo
        echo -n "${BOLD}${YELLOW}Have you checked your progress upto Task 3 ? (Y/N): ${RESET}"
        read -r user_input
        if [[ "$user_input" == "Y" || "$user_input" == "y" ]]; then
            echo
            echo "${BOLD}${GREEN}Great! Proceeding to the next steps...${RESET}"
            echo
            break
        elif [[ "$user_input" == "N" || "$user_input" == "n" ]]; then
            echo
            echo "${BOLD}${RED}Please check your progress upto Task 3 and then press Y to continue.${RESET}"
        else
            echo
            echo "${BOLD}${MAGENTA}Invalid input. Please enter Y or N.${RESET}"
        fi
    done
}

# Call function to check progress before proceeding
check_progress

# Step 11: Detach the orphaned disk
echo "${BOLD}${RED}Detaching the orphaned disk...${RESET}"
gcloud compute instances detach-disk disk-instance --device-name=$ORPHANED_DISK --zone=$ZONE

# Step 12: Describe the orphaned disk again
echo "${BOLD}${GREEN}Describing the orphaned disk after detachment...${RESET}"
gcloud compute disks describe $ORPHANED_DISK --zone=$ZONE --format=json | jq

# Step 13: Disable and re-enable Cloud Functions API
echo "${BOLD}${YELLOW}Disabling and re-enabling Cloud Functions API...${RESET}"
gcloud services disable cloudfunctions.googleapis.com

sleep 5

gcloud services enable cloudfunctions.googleapis.com

sleep 30

# Step 14: Add IAM policy binding for Artifact Registry reader role
echo "${BOLD}${BLUE}Adding IAM policy binding for Artifact Registry reader...${RESET}"
gcloud projects add-iam-policy-binding $PROJECT_ID \
--member="serviceAccount:qwiklabs-gcp-01-7864202acea1@appspot.gserviceaccount.com" \
--role="roles/artifactregistry.reader"

# Step 15: Enable Cloud Run API
echo "${BOLD}${MAGENTA}Enabling Cloud Run API...${RESET}"
gcloud services enable run.googleapis.com

sleep 30

# Step 16: Deploy the Cloud Function
echo "${BOLD}${CYAN}Deploying the Cloud Function...${RESET}"
cd ~/gsp648/unattached-pd
gcloud functions deploy delete_unattached_pds --gen2 --trigger-http --runtime=python39 --region $REGION --allow-unauthenticated

# Step 17: Get the Cloud Function URL
echo "${BOLD}${RED}Fetching the Cloud Function URL...${RESET}"
export FUNCTION_URL=$(gcloud functions describe delete_unattached_pds --format=json --region $REGION | jq -r '.url')

# Step 18: Create an App Engine application
echo "${BOLD}${GREEN}Creating an App Engine application...${RESET}"
gcloud app create --region=$REGION

# Step 29: Create a Cloud Scheduler job
echo "${BOLD}${YELLOW}Creating a Cloud Scheduler job...${RESET}"
gcloud scheduler jobs create http unattached-pd-job \
--schedule="* 2 * * *" \
--uri=$FUNCTION_URL \
--location=$REGION

sleep 60

# Step 20: Run the Cloud Scheduler job
echo "${BOLD}${BLUE}Running the Cloud Scheduler job...${RESET}"
gcloud scheduler jobs run unattached-pd-job \
--location=$REGION

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
