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

#---------------------------------------------------- START --------------------------------------------------#

echo -e "${BG_MAGENTA}${BOLD}Starting Execution...${RESET}"

# Step 1: Export Project ID and Project Number
echo -e "${CYAN}${BOLD}Retrieving Project ID and Project Number...${RESET}"
export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_NUMBER=$(gcloud projects describe ${PROJECT_ID} \
    --format="value(projectNumber)")

# Step 2: Get the zone from gcloud
echo -e "${CYAN}${BOLD}Retrieving the zone...${RESET}"
export ZONE=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-zone])")

# Step 3: Enable IAP API
echo -e "${YELLOW}${BOLD}Enabling IAP API...${RESET}"
gcloud services enable iap.googleapis.com

# Step 4: Create Linux VM with IAP
echo -e "${GREEN}${BOLD}Creating Linux IAP instance...${RESET}"
gcloud compute instances create linux-iap \
    --project=$DEVSHELL_PROJECT_ID \
    --zone=$ZONE \
    --machine-type=e2-medium \
    --network-interface=stack-type=IPV4_ONLY,subnet=default,no-address

# Step 5: Create Windows VM with IAP
echo -e "${GREEN}${BOLD}Creating Windows IAP instance...${RESET}"
gcloud compute instances create windows-iap \
    --project=$DEVSHELL_PROJECT_ID \
    --zone=$ZONE \
    --machine-type=e2-medium \
    --network-interface=stack-type=IPV4_ONLY,subnet=default,no-address \
    --create-disk=auto-delete=yes,boot=yes,device-name=windows-iap,image=projects/windows-cloud/global/images/windows-server-2016-dc-v20240313,mode=rw,size=50,type=projects/$DEVSHELL_PROJECT_ID/zones/$ZONE/diskTypes/pd-standard \
    --no-shielded-secure-boot \
    --shielded-vtpm \
    --shielded-integrity-monitoring \
    --labels=goog-ec-src=vm_add-gcloud \
    --reservation-affinity=any

# Step 6: Create Windows Connectivity VM with IAP
echo -e "${GREEN}${BOLD}Creating Windows Connectivity IAP instance...${RESET}"
gcloud compute instances create windows-connectivity \
    --project=$DEVSHELL_PROJECT_ID \
    --zone=$ZONE \
    --machine-type=e2-medium \
    --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=default \
    --metadata=enable-oslogin=true \
    --maintenance-policy=MIGRATE \
    --provisioning-model=STANDARD \
    --scopes=https://www.googleapis.com/auth/cloud-platform \
    --create-disk=auto-delete=yes,boot=yes,device-name=windows-connectivity,image=projects/qwiklabs-resources/global/images/iap-desktop-v001,mode=rw,size=50,type=projects/$DEVSHELL_PROJECT_ID/zones/$ZONE/diskTypes/pd-standard \
    --no-shielded-secure-boot \
    --shielded-vtpm \
    --shielded-integrity-monitoring \
    --labels=goog-ec-src=vm_add-gcloud \
    --reservation-affinity=any

# Step 7: Create firewall rule for IAP
echo -e "${BLUE}${BOLD}Creating firewall rule for IAP...${RESET}"
gcloud compute firewall-rules create allow-ingress-from-iap \
  --network default \
  --allow tcp:22,tcp:3389 \
  --source-ranges 35.235.240.0/20

# Step 8: Open Firewall and IAP console URLs
echo -e "${MAGENTA}${BOLD}View Firewall Rule and IAP Settings...${RESET}"
echo -e "Firewall Rule URL: ${BLUE}https://console.cloud.google.com/net-security/firewall-manager/firewall-policies/details/allow-ingress-from-iap?project=$DEVSHELL_PROJECT_ID${RESET}"
echo -e "IAP Settings URL: ${BLUE}https://console.cloud.google.com/security/iap?tab=ssh-tcp-resources&project=$DEVSHELL_PROJECT_ID${RESET}"

# Blank Line
echo ""

# Step 9: Display the service account
echo -e "${CYAN}${BOLD}Service Account: $PROJECT_NUMBER-compute@developer.gserviceaccount.com${RESET}"

# Adding one blank line
echo -e "\n"

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
    )
    RANDOM_INDEX=$((RANDOM % ${#MESSAGES[@]}))
    echo -e "${BOLD}${MESSAGES[$RANDOM_INDEX]}"
}

# Function to display a random thank-you message
function random_thank_you() {
    MESSAGES=(
        "${GREEN}Thanks for your support! You’re awesome!${RESET}"
        "${CYAN}Thank you! Your subscription means a lot!${RESET}"
        "${YELLOW}Much appreciated! Keep enjoying the content!${RESET}"
        "${BLUE}Thanks a ton! Your support makes us better!${RESET}"
        "${MAGENTA}Grateful for your support! You’re amazing!${RESET}"
        "${RED}Thank you for subscribing! We’re thrilled to have you!${RESET}"
        "${CYAN}Thanks for being part of our community! You’re valued!${RESET}"
        "${GREEN}You rock! Thanks for subscribing and supporting us!${RESET}"
        "${YELLOW}Thanks for helping us grow! Your support matters!${RESET}"
        "${BLUE}Big thanks to you! Keep enjoying our content!${RESET}"
        "${MAGENTA}Your subscription means the world to us. Thank you!${RESET}"
        "${RED}You’re the best! Thanks for supporting our channel!${RESET}"
        "${CYAN}Thank you! Your subscription helps us create more content!${RESET}"
        "${GREEN}We’re so grateful for your subscription! Thank you!${RESET}"
        "${YELLOW}Huge thanks! You make a big difference by subscribing!${RESET}"
        "${BLUE}Thanks for joining us! Your support is truly appreciated!${RESET}"
    )
    RANDOM_INDEX=$((RANDOM % ${#MESSAGES[@]}))
    echo -e "${BOLD}${MESSAGES[$RANDOM_INDEX]}"
}

# Function to display a random question
function random_question() {
    QUESTIONS=(
        "Have you subscribed to the YouTube channel yet? [Y/N]"
        "Did you hit the subscribe button on our YouTube channel? [Y/N]"
        "Are you part of our growing community on YouTube? [Y/N]"
        "Did you join the fun by subscribing to QUICK GCP LAB? [Y/N]"
        "Have you clicked the subscribe button for new tutorials? [Y/N]"
        "Are you a subscriber to our YouTube channel? [Y/N]"
        "Want to stay updated with our latest content? Subscribe now! [Y/N]"
        "Ready to dive deeper into cloud computing with us? Subscribe! [Y/N]"
        "Would you like to keep learning with us? Hit subscribe! [Y/N]"
        "Do you enjoy our content? Subscribe to stay updated! [Y/N]"
        "Do you want to see more labs and tutorials? Subscribe to our channel! [Y/N]"
    )
    RANDOM_INDEX=$((RANDOM % ${#QUESTIONS[@]}))
    echo -e "${BOLD}${WHITE}${QUESTIONS[$RANDOM_INDEX]}${RESET}"
}

# Function to display the "Please Subscribe" message with variety
function random_subscribe_message() {
    MESSAGES=(
        "${BOLD}${RED}Please ${GREEN}Subscribe ${YELLOW}to ${BLUE}QUICK ${MAGENTA}GCP ${CYAN}LAB!${RESET}"
        "${BOLD}${CYAN}Don’t miss out! Subscribe to ${MAGENTA}QUICK ${GREEN}GCP ${BLUE}LAB!${RESET}"
        "${BOLD}${RED}Hit that subscribe button for more amazing content from ${CYAN}QUICK ${GREEN}GCP ${MAGENTA}LAB!${RESET}"
        "${BOLD}${YELLOW}Join the ${GREEN}QUICK ${CYAN}GCP ${MAGENTA}LAB community! Subscribe now!${RESET}"
        "${BOLD}${BLUE}Want more tutorials? ${MAGENTA}SUBSCRIBE ${YELLOW}to ${CYAN}QUICK ${GREEN}GCP ${BLUE}LAB!${RESET}"
        "${BOLD}${RED}Your subscription helps us bring more tutorials to you! Please ${CYAN}subscribe to ${MAGENTA}QUICK ${GREEN}GCP ${BLUE}LAB!${RESET}"
        "${BOLD}${YELLOW}Subscribe to ${CYAN}QUICK ${MAGENTA}GCP ${GREEN}LAB to stay updated on all our tutorials!${RESET}"
        "${BOLD}${CYAN}Keep learning with us! ${GREEN}Subscribe to ${MAGENTA}QUICK ${YELLOW}GCP ${RED}LAB!${RESET}"
        "${BOLD}${MAGENTA}Support us and get access to exclusive tutorials by subscribing to ${CYAN}QUICK ${GREEN}GCP ${BLUE}LAB!${RESET}"
        "${BOLD}${BLUE}Love the content? Subscribe to ${MAGENTA}QUICK ${CYAN}GCP ${GREEN}LAB!${RESET}"
        "${BOLD}${RED}Help us grow by subscribing to ${CYAN}QUICK ${MAGENTA}GCP ${YELLOW}LAB! Your support is crucial!${RESET}"
        "${BOLD}${GREEN}Don’t forget to hit subscribe to stay up to date with ${CYAN}QUICK ${MAGENTA}GCP ${BLUE}LAB!${RESET}"
        "${BOLD}${YELLOW}Want to join the ${BLUE}QUICK ${MAGENTA}GCP ${CYAN}LAB family? Hit subscribe!${RESET}"
        "${BOLD}${MAGENTA}We appreciate your support! Please ${CYAN}subscribe to ${GREEN}QUICK ${RED}GCP ${BLUE}LAB!${RESET}"
        "${BOLD}${CYAN}Your subscription makes a difference! Help us grow by subscribing to ${MAGENTA}QUICK ${YELLOW}GCP ${GREEN}LAB!${RESET}"
        "${BOLD}${RED}Every click counts! Please subscribe to ${BLUE}QUICK ${MAGENTA}GCP ${CYAN}LAB!${RESET}"
    )
    RANDOM_INDEX=$((RANDOM % ${#MESSAGES[@]}))
    echo -e "${BOLD}${MESSAGES[$RANDOM_INDEX]}"
}

# Display a random congratulatory message
random_congrats

# Add a single blank line between congratulatory message and the prompt
echo -e "\n"  # Adding one blank line

# Display a random question
random_question

# Read the user input
read -p "Enter your choice: " CHOICE

# Handle user input
case "${CHOICE^^}" in
    Y)
        random_thank_you
        ;;
    N)
        random_subscribe_message
        echo -e "${BOLD}${CYAN}https://www.youtube.com/@quickgcplab${RESET}"
        ;;
    *)
        echo -e "${BOLD}${RED}Invalid choice! Please enter Y or N.${RESET}"
        ;;
esac

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
