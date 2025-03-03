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

# Random Thank You Messages
THANK_YOU_MESSAGES=(
    "Thanks for providing the details!"
    "Appreciate your input!"
    "Your details have been recorded!"
    "Thanks for your response!"
    "Your input is valuable, thank you!"
)

# Pick a random thank you message
RANDOM_THANK_YOU=${THANK_YOU_MESSAGES[$RANDOM % ${#THANK_YOU_MESSAGES[@]}]}

#----------------------------------------------------start--------------------------------------------------#

echo "${RANDOM_BG_COLOR}${RANDOM_TEXT_COLOR}${BOLD}Starting Execution${RESET}"

set_cloudshell_env() {
    echo
    echo -n "${CYAN}${BOLD}Enter Repository Name: ${RESET}"
    read REPO
    echo -n "${MAGENTA}${BOLD}Enter Docker Image: ${RESET}"
    read DCKR_IMG
    echo -n "${YELLOW}${BOLD}Enter Tag Name: ${RESET}"
    read TAG

    export REPO="$REPO"
    export DCKR_IMG="$DCKR_IMG"
    export TAG="$TAG"

    echo

    echo "${RANDOM_TEXT_COLOR}${BOLD}$RANDOM_THANK_YOU${RESET}"

    echo

}

set_cloudshell_env

# Step 1: Fetching region and zone details...
echo "${CYAN}${BOLD}Fetching region and zone details...${RESET}"

export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")

export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")

# Step 2: Sourcing setup script...
echo "${MAGENTA}${BOLD}Sourcing setup script...${RESET}"
source <(gsutil cat gs://cloud-training/gsp318/marking/setup_marking_v2.sh)

# Step 3: Downloading and extracting application...
echo "${GREEN}${BOLD}Downloading and extracting application...${RESET}"
gsutil cp gs://spls/gsp318/valkyrie-app.tgz .
tar -xzf valkyrie-app.tgz
cd valkyrie-app

# Step 4: Creating Dockerfile...
echo "${YELLOW}${BOLD}Creating Dockerfile...${RESET}"
cat > Dockerfile <<EOF
FROM golang:1.10
WORKDIR /go/src/app
COPY source .
RUN go install -v
ENTRYPOINT ["app","-single=true","-port=8080"]
EOF

# Step 5: Building Docker image...
echo "${BLUE}${BOLD}Building Docker image...${RESET}"
docker build -t $DCKR_IMG:$TAG .

# Step 6: Executing Step 1 script...
echo "${MAGENTA}${BOLD}Executing Step 1 script...${RESET}"
cd ..
./step1_v2.sh

# Step 7: Running Docker container...
echo "${CYAN}${BOLD}Running Docker container...${RESET}"
cd valkyrie-app
docker run -d -p 8080:8080 $DCKR_IMG:$TAG

# Step 8: Executing Step 2 script...
echo "${MAGENTA}${BOLD}Executing Step 2 script...${RESET}"
cd ..
./step2_v2.sh

cd valkyrie-app

# Step 9: Creating Artifact Repository...
echo "${YELLOW}${BOLD}Creating Artifact Repository...${RESET}"
gcloud artifacts repositories create $REPO \
    --repository-format=docker \
    --location=$REGION \
    --description="awesome lab" \
    --async

# Step 10: Configuring Docker authentication...
echo "${BLUE}${BOLD}Configuring Docker authentication...${RESET}"
gcloud auth configure-docker $REGION-docker.pkg.dev --quiet

sleep 30

# Step 11: Tagging and pushing Docker image...
echo "${CYAN}${BOLD}Tagging and pushing Docker image...${RESET}"

Image_ID=$(docker images --format='{{.ID}}')

docker tag $Image_ID $REGION-docker.pkg.dev/$DEVSHELL_PROJECT_ID/$REPO/$DCKR_IMG:$TAG

docker push $REGION-docker.pkg.dev/$DEVSHELL_PROJECT_ID/$REPO/$DCKR_IMG:$TAG

# Step 12: Updating Kubernetes deployment...
echo "${GREEN}${BOLD}Updating Kubernetes deployment...${RESET}"
sed -i s#IMAGE_HERE#$REGION-docker.pkg.dev/$DEVSHELL_PROJECT_ID/$REPO/$DCKR_IMG:$TAG#g k8s/deployment.yaml

# Step 13: Configuring Kubernetes cluster...
echo "${YELLOW}${BOLD}Configuring Kubernetes cluster...${RESET}"
gcloud container clusters get-credentials valkyrie-dev --zone $ZONE

# Step 14: Deploying application to Kubernetes...
echo "${BLUE}${BOLD}Deploying application to Kubernetes...${RESET}"
kubectl create -f k8s/deployment.yaml
kubectl create -f k8s/service.yaml

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