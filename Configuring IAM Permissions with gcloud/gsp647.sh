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

gcloud auth login --quiet

# Step 1: Set Compute Zone & Region
echo "${BOLD}${BLUE}Setting Compute Zone & Region${RESET}"
export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")

export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")

# Step 2: Configure Compute Settings
echo "${BOLD}${MAGENTA}Configuring Compute Settings${RESET}"
gcloud config set compute/region $REGION
gcloud config set compute/zone $ZONE

# Step 3: Create lab-1 Instance
echo "${BOLD}${YELLOW}Creating lab-1 VM instance${RESET}"
gcloud compute instances create lab-1 --zone $ZONE --machine-type=e2-standard-2

# Step 4: Choose a new zone in the same region
echo "${BOLD}${GREEN}Selecting a new zone in same region${RESET}"
export NEWZONE=$(gcloud compute zones list --filter="name~'^$REGION'" \
  --format="value(name)" | grep -v "^$ZONE$" | head -n 1)

# Step 5: Set new zone in gcloud config
echo "${BOLD}${RED}Setting new zone in gcloud config${RESET}"
gcloud config set compute/zone $NEWZONE

# Function to prompt user to check their progress
function check_progress {
    while true; do
        echo
        echo -n "${BOLD}${YELLOW}Have you checked your progress for Task 1 ? (Y/N): ${RESET}"
        read -r user_input
        if [[ "$user_input" == "Y" || "$user_input" == "y" ]]; then
            echo
            echo "${BOLD}${GREEN}Great! Proceeding to the next steps...${RESET}"
            echo
            break
        elif [[ "$user_input" == "N" || "$user_input" == "n" ]]; then
            echo
            echo "${BOLD}${RED}Please check your progress for Task 1 and then press Y to continue.${RESET}"
        else
            echo
            echo "${BOLD}${MAGENTA}Invalid input. Please enter Y or N.${RESET}"
        fi
    done
}

# Call function to check progress before proceeding
check_progress

# Step 6: Create a new gcloud config for user2
echo "${BOLD}${BLUE}Creating a new gcloud config for user2${RESET}"
gcloud config configurations create user2 --quiet

# Step 7: Authenticate user2
echo "${BOLD}${YELLOW}Authenticating user2${RESET}"
gcloud auth login --no-launch-browser --quiet

# Step 8: Set default project/zone/region for user2
echo "${BOLD}${MAGENTA}Setting project, zone, region for user2${RESET}"
gcloud config set project $(gcloud config get-value project --configuration=default) --configuration=user2
gcloud config set compute/zone $(gcloud config get-value compute/zone --configuration=default) --configuration=user2
gcloud config set compute/region $(gcloud config get-value compute/region --configuration=default) --configuration=user2

# Step 9: Switch back to default config
echo "${BOLD}${GREEN}Switching back to default config${RESET}"
gcloud config configurations activate default

# Step 10: Install dependencies
echo "${BOLD}${RED}Installing epel-release and jq${RESET}"
sudo yum -y install epel-release
sudo yum -y install jq

echo

# Step 11: Prompt for input values and export
echo "${BOLD}${CYAN}Prompting for PROJECTID2, USERID2, and ZONE2${RESET}"
echo
get_and_export_values() {
  # Prompt user for PROJECTID2
echo -n "${BOLD}${BLUE}Enter the PROJECTID2: ${RESET}"
read PROJECTID2
echo

# Prompt user for USERID2
echo -n "${BOLD}${MAGENTA}Enter the USERID2: ${RESET}"
read USERID2
echo

# Prompt user for ZONE2
echo -n "${BOLD}${CYAN}Enter the ZONE2: ${RESET}"
read ZONE2
echo

  # Export the values in the current session
  export PROJECTID2
  export USERID2
  export ZONE2

  # Append the export statements to ~/.bashrc with actual values
  echo "export PROJECTID2=$PROJECTID2" >> ~/.bashrc
  echo "export USERID2=$USERID2" >> ~/.bashrc
  echo "export ZONE2=$ZONE2" >> ~/.bashrc
}

get_and_export_values

echo

# Step 12: Grant viewer role to user2
echo "${BOLD}${YELLOW}Granting viewer role to user2${RESET}"
. ~/.bashrc
gcloud projects add-iam-policy-binding $PROJECTID2 --member user:$USERID2 --role=roles/viewer

# Step 13: Switch to user2 config
echo "${BOLD}${MAGENTA}Switching to user2 config${RESET}"
gcloud config configurations activate user2

# Step 14: Set project for user2
echo "${BOLD}${GREEN}Setting project for user2${RESET}"
gcloud config set project $PROJECTID2

# Step 14: Switch to default config again
echo "${BOLD}${RED}Switching to default config${RESET}"
gcloud config configurations activate default

# Step 15: Create custom role devops
echo "${BOLD}${CYAN}Creating custom IAM role 'devops'${RESET}"
gcloud iam roles create devops --project $PROJECTID2 --permissions "compute.instances.create,compute.instances.delete,compute.instances.start,compute.instances.stop,compute.instances.update,compute.disks.create,compute.subnetworks.use,compute.subnetworks.useExternalIp,compute.instances.setMetadata,compute.instances.setServiceAccount"

# Step 16: Assign roles to user2
echo "${BOLD}${BLUE}Assigning IAM roles to user2${RESET}"
gcloud projects add-iam-policy-binding $PROJECTID2 --member user:$USERID2 --role=roles/iam.serviceAccountUser

gcloud projects add-iam-policy-binding $PROJECTID2 --member user:$USERID2 --role=projects/$PROJECTID2/roles/devops

# Step 17: Switch to user2 config again
echo "${BOLD}${YELLOW}Switching to user2 config${RESET}"
gcloud config configurations activate user2

# Step 18: Create lab-2 instance
echo "${BOLD}${MAGENTA}Creating lab-2 VM instance${RESET}"
gcloud compute instances create lab-2 --zone $ZONE2 --machine-type=e2-standard-2

# Step 19: Switch to default config
echo "${BOLD}${GREEN}Switching to default config${RESET}"
gcloud config configurations activate default

# Step 20: Set project to PROJECTID2
echo "${BOLD}${RED}Setting project to PROJECTID2${RESET}"
gcloud config set project $PROJECTID2

# Step 21: Create service account named devops
echo "${BOLD}${CYAN}Creating service account 'devops'${RESET}"
gcloud iam service-accounts create devops --display-name devops

# Step 22: Get service account email
echo "${BOLD}${BLUE}Retrieving service account email${RESET}"
SA=$(gcloud iam service-accounts list --format="value(email)" --filter "displayName=devops")

# Step 23: Grant service account roles
echo "${BOLD}${YELLOW}Granting IAM roles to service account${RESET}"
gcloud projects add-iam-policy-binding $PROJECTID2 --member serviceAccount:$SA --role=roles/iam.serviceAccountUser

gcloud projects add-iam-policy-binding $PROJECTID2 --member serviceAccount:$SA --role=roles/compute.instanceAdmin

# Step 24: Create lab-3 instance with service account
echo "${BOLD}${MAGENTA}Creating lab-3 VM instance using service account${RESET}"
gcloud compute instances create lab-3 --zone $ZONE2 --machine-type=e2-standard-2 --service-account $SA --scopes "https://www.googleapis.com/auth/compute"

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