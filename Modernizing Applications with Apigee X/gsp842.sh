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

# Step 0: Get the default compute region
echo "${GREEN}${BOLD}Retrieving Default Compute Region${RESET}"
export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")

# Step 1: Enable the Geocoding Backend API
echo -e "${CYAN}${BOLD}Enable the Geocoding Backend API${RESET}"
gcloud services enable geocoding-backend.googleapis.com

# Step 2: Clone the training data analyst repository
echo -e "${YELLOW}${BOLD}Clone the training data analyst repository${RESET}"
git clone --depth 1 https://github.com/GoogleCloudPlatform/training-data-analyst

# Step 3: Create a symbolic link for the Apigee directory
echo -e "${CYAN}${BOLD}Create a symbolic link for the Apigee directory${RESET}"
ln -s ~/training-data-analyst/quests/develop-apis-apigee ~/develop-apis-apigee

# Step 4: Navigate to the rest-backend directory
echo -e "${GREEN}${BOLD}Navigate to the rest-backend directory${RESET}"
cd ~/develop-apis-apigee/rest-backend

# Step 5: Update the configuration file
echo -e "${YELLOW}${BOLD}Update the configuration file to use the ${REGION} region${RESET}"
sed -i "s/us-west1/$REGION/g" config.sh

# Step 6: Display and execute the init-project.sh script
echo -e "${CYAN}${BOLD}Display and execute the init-project.sh script${RESET}"
cat init-project.sh
./init-project.sh

# Step 7: Display and execute the init-service.sh script
echo -e "${GREEN}${BOLD}Display and execute the init-service.sh script${RESET}"
cat init-service.sh
./init-service.sh

# Step 8: Display and execute the deploy.sh script
echo -e "${YELLOW}${BOLD}Display and execute the deploy.sh script${RESET}"
cat deploy.sh
./deploy.sh

# Step 9: Export the REST backend host URL
echo -e "${CYAN}${BOLD}Export the REST backend host URL${RESET}"
export RESTHOST=$(gcloud run services describe simplebank-rest --platform managed --region $REGION --format 'value(status.url)')
echo "export RESTHOST=${RESTHOST}" >> ~/.bashrc

# Step 10: Check the REST service status
echo -e "${GREEN}${BOLD}Check the REST service status${RESET}"
curl -H "Authorization: Bearer $(gcloud auth print-identity-token)" -X GET "${RESTHOST}/_status"

echo

# Step 11: Add a customer record to the REST service
echo -e "${YELLOW}${BOLD}Add a customer record to the REST service${RESET}"
curl -H "Authorization: Bearer $(gcloud auth print-identity-token)" -H "Content-Type: application/json" -X POST "${RESTHOST}/customers" -d '{"lastName": "Diallo", "firstName": "Temeka", "email": "temeka@example.com"}'

echo

# Step 12: Retrieve customer details
echo -e "${CYAN}${BOLD}Retrieve customer details${RESET}"
curl -H "Authorization: Bearer $(gcloud auth print-identity-token)" -X GET "${RESTHOST}/customers/temeka@example.com"

echo

# Step 13: Import sample data into Firestore
echo -e "${GREEN}${BOLD}Import sample data into Firestore${RESET}"
gcloud firestore import gs://cloud-training/api-dev-quest/firestore/example-data

# Step 14: List all ATMs using the REST service
echo -e "${YELLOW}${BOLD}List all ATMs using the REST service${RESET}"
curl -H "Authorization: Bearer $(gcloud auth print-identity-token)" -X GET "${RESTHOST}/atms"

echo

# Step 15: Retrieve a specific ATM's details
echo -e "${CYAN}${BOLD}Retrieve a specific ATM's details${RESET}"
curl -H "Authorization: Bearer $(gcloud auth print-identity-token)" -X GET "${RESTHOST}/atms/spruce-goose"

echo

# Step 16: Create a service account for Apigee internal access
echo -e "${GREEN}${BOLD}Create a service account for Apigee internal access${RESET}"
gcloud iam service-accounts create apigee-internal-access \
--display-name="Service account for internal access by Apigee proxies" \
--project=${GOOGLE_CLOUD_PROJECT}

# Step 17: Add IAM policy binding to the REST service
echo -e "${YELLOW}${BOLD}Add IAM policy binding to the REST service${RESET}"
gcloud run services add-iam-policy-binding simplebank-rest \
--member="serviceAccount:apigee-internal-access@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com" \
--role=roles/run.invoker --region=$REGION \
--project=${GOOGLE_CLOUD_PROJECT}

# Step 18: Get the REST service URL
echo -e "${CYAN}${BOLD}Get the REST service URL${RESET}"
gcloud run services describe simplebank-rest --platform managed --region $REGION --format 'value(status.url)'

# Step 19: Create an API key for the Geocoding API
echo -e "${GREEN}${BOLD}Create an API key for the Geocoding API${RESET}"
API_KEY=$(gcloud alpha services api-keys create --project=${GOOGLE_CLOUD_PROJECT} --display-name="Geocoding API key for Apigee" --api-target=service=geocoding_backend --format "value(response.keyString)")
echo "export API_KEY=${API_KEY}" >> ~/.bashrc
echo "API_KEY=${API_KEY}"

# Step 20: Monitor runtime instance and attach environment
echo -e "${YELLOW}${BOLD}Monitor runtime instance and attach environment${RESET}"
export INSTANCE_NAME=eval-instance; export ENV_NAME=eval; export PREV_INSTANCE_STATE=; echo "waiting for runtime instance ${INSTANCE_NAME} to be active"; while : ; do export INSTANCE_STATE=$(curl -s -H "Authorization: Bearer $(gcloud auth print-access-token)" -X GET "https://apigee.googleapis.com/v1/organizations/${GOOGLE_CLOUD_PROJECT}/instances/${INSTANCE_NAME}" | jq "select(.state != null) | .state" --raw-output); [[ "${INSTANCE_STATE}" == "${PREV_INSTANCE_STATE}" ]] || (echo; echo "INSTANCE_STATE=${INSTANCE_STATE}"); export PREV_INSTANCE_STATE=${INSTANCE_STATE}; [[ "${INSTANCE_STATE}" != "ACTIVE" ]] || break; echo -n "."; sleep 5; done; echo; echo "instance created, waiting for environment ${ENV_NAME} to be attached to instance"; while : ; do export ATTACHMENT_DONE=$(curl -s -H "Authorization: Bearer $(gcloud auth print-access-token)" -X GET "https://apigee.googleapis.com/v1/organizations/${GOOGLE_CLOUD_PROJECT}/instances/${INSTANCE_NAME}/attachments" | jq "select(.attachments != null) | .attachments[] | select(.environment == \"${ENV_NAME}\") | .environment" --join-output); [[ "${ATTACHMENT_DONE}" != "${ENV_NAME}" ]] || break; echo -n "."; sleep 5; done; echo "***ORG IS READY TO USE***";

echo

# Provide the Apigee proxy creation URL
echo -e "${BLUE}${BOLD}Go to this link to create an Apigee proxy: ${RESET}""https://console.cloud.google.com/apigee/proxy-create?project=$DEVSHELL_PROJECT_ID"

echo

# Display backend URL and service account details
echo -e "${YELLOW}${BOLD}Backend URL: ${RESET}""$(gcloud run services describe simplebank-rest --platform managed --region $REGION --format='value(status.url)')"

echo

echo -e "${CYAN}${BOLD}Copy this service account: ${RESET}""apigee-internal-access@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com"

echo

echo -e "${GREEN}${BOLD}Copy this API KEY: ${RESET}""apikey=${API_KEY}"

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
