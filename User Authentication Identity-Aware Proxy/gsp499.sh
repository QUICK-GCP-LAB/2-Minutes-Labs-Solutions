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

COLORS=(
  "$(tput setaf 1)"  # Red
  "$(tput setaf 2)"  # Green
  "$(tput setaf 3)"  # Yellow
  "$(tput setaf 4)"  # Blue
  "$(tput setaf 5)"  # Magenta
  "$(tput setaf 6)"  # Cyan
)

CREATE_MESSAGES=(
  "Time to register your app: "
  "Let's begin by creating OAuth consent credentials: "
  "Set up your client app in Google Cloud: "
  "Start by defining your OAuth screen here: "
)

IAP_MESSAGES=(
  "Now head over to configure IAP: "
  "Enable and manage IAP settings below: "
  "Secure your app with Identity-Aware Proxy: "
  "Next stop: IAP console "
)

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

# Step 1: Enable IAP API
echo "${BOLD}${RED}Step 1: Enabling IAP API...${RESET}"
gcloud services enable iap.googleapis.com

# Step 2: Download sample application
echo "${BOLD}${GREEN}Step 2: Downloading sample application...${RESET}"
gsutil cp gs://spls/gsp499/user-authentication-with-iap.zip .

# Step 3: Unzip the downloaded file
echo "${BOLD}${YELLOW}Step 3: Unzipping the application package...${RESET}"
unzip user-authentication-with-iap.zip

# Step 4: Navigate to HelloWorld directory
echo "${BOLD}${BLUE}Step 4: Navigating to 1-HelloWorld directory...${RESET}"
cd user-authentication-with-iap/1-HelloWorld

# Step 5: Disable Flex API
echo "${BOLD}${RED}Disabling Flex API...${RESET}"
gcloud services enable appengineflex.googleapis.com

# Step 3: Modify app.yaml for Python 3.9
echo "${BOLD}${GREEN}Step 3: Updating app.yaml to Python 3.9...${RESET}"
sed -i 's/python37/python39/g' app.yaml

# Step 4: Create App Engine app
echo "${BOLD}${MAGENTA}Step 4: Creating App Engine application...${RESET}"
gcloud app create --region=$REGION

# Step 5: Deploy HelloWorld application with retry
echo "${BOLD}${RED}Step 5: Deploying HelloWorld application...${RESET}"
deploy_function() {
  yes | gcloud app deploy
}

deploy_success=false

while [ "$deploy_success" = false ]; do
  if deploy_function; then
    echo "${BOLD}${GREEN}Function deployed successfully...${RESET}"
    deploy_success=true
  else
    echo "${BOLD}${YELLOW}Retrying deployment in 10 seconds...${RESET}"
    sleep 10
  fi
done

echo "${BOLD}${MAGENTA}Navigating to 2-HelloUser and deploying...${RESET}"
cd ~/user-authentication-with-iap/2-HelloUser

sed -i 's/python37/python39/g' app.yaml

deploy_function() {
  yes | gcloud app deploy
}

deploy_success=false

while [ "$deploy_success" = false ]; do
  if deploy_function; then
    echo "${BOLD}${GREEN}Function deployed successfully...${RESET}"
    deploy_success=true
  else
    echo "${BOLD}${YELLOW}Retrying deployment in 10 seconds...${RESET}"
    sleep 10
  fi
done

echo "${BOLD}${MAGENTA}Navigating to 3-HelloVerifiedUser and deploying...${RESET}"
cd ~/user-authentication-with-iap/3-HelloVerifiedUser

sed -i 's/python37/python39/g' app.yaml

deploy_function() {
  yes | gcloud app deploy
}

deploy_success=false

while [ "$deploy_success" = false ]; do
  if deploy_function; then
    echo "${BOLD}${GREEN}Function deployed successfully...${RESET}"
    deploy_success=true
  else
    echo "${BOLD}${YELLOW}Retrying deployment in 10 seconds...${RESET}"
    sleep 10
  fi
done

# Step 7: Generate application details JSON
echo "${BOLD}${BLUE}Step 7: Generating application details JSON...${RESET}"
EMAIL="$(gcloud config get-value core/account 2>/dev/null)"
LINK=$(gcloud app browse 2>/dev/null | grep -o 'https://.*')
LINKU=${LINK#https://}
PROJECT_ID="$DEVSHELL_PROJECT_ID"

cat > details.json << EOF
{
  "App name": "IAP Example",
  "Application home page": "$LINK",
  "Application privacy Policy link": "$LINK/privacy",
  "Authorized domains": "$LINKU",
  "Developer Contact Information": "$EMAIL"
}
EOF

echo

jq -r 'to_entries[] | "\(.key): \(.value)"' details.json | while IFS=: read -r key value; do
  COLOR=${COLORS[$RANDOM % ${#COLORS[@]}]}
  printf "${BOLD}${COLOR}%-35s${RESET}: %s\n" "$key" "$value"
done

# OAuth client creation
echo
RANDOM_MSG1=${CREATE_MESSAGES[$RANDOM % ${#CREATE_MESSAGES[@]}]}
COLOR1=${COLORS[$RANDOM % ${#COLORS[@]}]}
echo "${BOLD}${COLOR1}${RANDOM_MSG1}${RESET}""https://console.cloud.google.com/auth/clients/create?project=$DEVSHELL_PROJECT_ID"

# IAP configuration
echo
RANDOM_MSG2=${IAP_MESSAGES[$RANDOM % ${#IAP_MESSAGES[@]}]}
COLOR2=${COLORS[$RANDOM % ${#COLORS[@]}]}
echo "${BOLD}${COLOR2}${RANDOM_MSG2}${RESET}""https://console.cloud.google.com/security/iap?project=$DEVSHELL_PROJECT_ID"

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