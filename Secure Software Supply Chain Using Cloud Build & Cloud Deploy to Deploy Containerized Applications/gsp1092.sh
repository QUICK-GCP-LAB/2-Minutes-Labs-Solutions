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

# Step 1: Get project and region
echo "${BLUE}${BOLD}Fetching PROJECT and REGION${RESET}"
export PROJECT=$(gcloud config get-value project)
export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")

# Step 2: Enable required services
echo "${MAGENTA}${BOLD}Enabling Google Cloud services${RESET}"
gcloud services enable run.googleapis.com
gcloud services enable clouddeploy.googleapis.com

# Step 3: Create an Artifact Registry repository
echo "${CYAN}${BOLD}Creating Artifact Registry repository${RESET}"
gcloud artifacts repositories create helloworld-repo --location=$REGION --repository-format=docker --project=$PROJECT

# Step 4: Create and navigate to the project directory
echo "${YELLOW}${BOLD}Setting up project directory${RESET}"
mkdir helloworld
cd helloworld

# Step 5: Create package.json
echo "${RED}${BOLD}Creating package.json${RESET}"
cat <<EOF > package.json
{
  "name": "helloworld",
  "description": "Simple hello world sample in Node",
  "version": "1.0.0",
  "private": true,
  "main": "index.js",
  "scripts": {
    "start": "node index.js"
  },
  "engines": {
    "node": ">=12.0.0"
  },
  "author": "Google LLC",
  "license": "Apache-2.0",
  "dependencies": {
    "express": "^4.17.1"
  }
}
EOF

# Step 6: Create index.js
echo "${GREEN}${BOLD}Creating index.js${RESET}"
cat > index.js <<'EOF_END'
const express = require('express');
const app = express();

app.get('/', (req, res) => {
  const name = process.env.NAME || 'World';
  res.send(`Hello ${name}!`);
});

const port = parseInt(process.env.PORT) || 8080;
app.listen(port, () => {
  console.log(`helloworld: listening on port ${port}`);
});
EOF_END

# Step 7: Build and submit the image
echo "${BLUE}${BOLD}Submitting build to Cloud Build${RESET}"
gcloud builds submit --pack image=$REGION-docker.pkg.dev/$PROJECT/helloworld-repo/helloworld

# Step 8: Create and navigate to the deployment directory
echo "${MAGENTA}${BOLD}Creating deployment directory${RESET}"
mkdir ~/deploy-cloudrun
cd ~/deploy-cloudrun

# Step 9: Create skaffold.yaml
echo "${CYAN}${BOLD}Creating skaffold.yaml${RESET}"
cat <<EOF > skaffold.yaml
apiVersion: skaffold/v3alpha1
kind: Config
metadata:
  name: deploy-run-quickstart
profiles:
- name: dev
  manifests:
    rawYaml:
    - run-dev.yaml
- name: prod
  manifests:
    rawYaml:
    - run-prod.yaml
deploy:
  cloudrun: {}
EOF

# Step 10: Create run-dev.yaml
echo "${YELLOW}${BOLD}Creating run-dev.yaml${RESET}"
cat <<EOF > run-dev.yaml
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: helloworld-dev
spec:
  template:
    spec:
      containers:
      - image: my-app-image
EOF

# Step 11: Create run-prod.yaml
echo "${RED}${BOLD}Creating run-prod.yaml${RESET}"
cat <<EOF > run-prod.yaml
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: helloworld-prod
spec:
  template:
    spec:
      containers:
      - image: my-app-image
EOF

# Step 12: Create clouddeploy.yaml
echo "${GREEN}${BOLD}Creating clouddeploy.yaml${RESET}"
cat <<EOF > clouddeploy.yaml
apiVersion: deploy.cloud.google.com/v1
kind: DeliveryPipeline
metadata:
  name: my-run-demo-app-1
description: main application pipeline
serialPipeline:
  stages:
  - targetId: run-dev
    profiles: [dev]
  - targetId: run-prod
    profiles: [prod]
---

apiVersion: deploy.cloud.google.com/v1
kind: Target
metadata:
  name: run-dev
description: Cloud Run development service
run:
  location: projects/$PROJECT/locations/$REGION
---

apiVersion: deploy.cloud.google.com/v1
kind: Target
metadata:
  name: run-prod
description: Cloud Run production service
run:
  location: projects/$PROJECT/locations/$REGION
EOF

# Step 13: Apply Cloud Deploy configuration
echo "${BLUE}${BOLD}Applying Cloud Deploy configuration${RESET}"
gcloud deploy apply --file clouddeploy.yaml --region=$REGION

# Step 14: Create release
echo "${MAGENTA}${BOLD}Creating release${RESET}"
deploy_and_promote() {
    DELIVERY_PIPELINE="my-run-demo-app-1"
    RELEASE_NAME="run-release-001"
    IMAGE_PATH="$REGION-docker.pkg.dev/$PROJECT/helloworld-repo/helloworld"

    gcloud deploy releases create $RELEASE_NAME --project=$PROJECT --region=$REGION --delivery-pipeline=$DELIVERY_PIPELINE --images=my-app-image=$IMAGE_PATH

    # Step 15: Monitor rollout status
    echo "${CYAN}${BOLD}Monitoring rollout status${RESET}"
    while true; do
        STATUS=$(gcloud deploy rollouts list --release=$RELEASE_NAME --delivery-pipeline=$DELIVERY_PIPELINE --region=$REGION --format="value(state)" --limit=1)
        PHASE_STATUS=$(gcloud deploy rollouts list --release=$RELEASE_NAME --delivery-pipeline=$DELIVERY_PIPELINE --region=$REGION --format="value(phases[0].state)" --limit=1)
        
        echo "${YELLOW}${BOLD}📢 Current Rollout State: $STATUS${RESET}"
        echo "${MAGENTA}${BOLD}📢 Deployment Phase State: $PHASE_STATUS${RESET}"

        if [[ "$STATUS" == "SUCCEEDED" && "$PHASE_STATUS" == "SUCCEEDED" ]]; then
                    echo "${GREEN}${BOLD}✅ Rollout succeeded! Promoting release...${RESET}"
            gcloud deploy releases promote --delivery-pipeline=$DELIVERY_PIPELINE --region=$REGION --release=$RELEASE_NAME --quiet
                    echo "${GREEN}${BOLD}🎉 Release successfully promoted!${RESET}"
            break
        elif [[ "$STATUS" == "FAILED" || "$PHASE_STATUS" == "FAILED" ]]; then
            echo "${RED}${BOLD}❌ Rollout failed! Exiting...${RESET}"
            exit 1
        else
            echo "${CYAN}${BOLD}⏳ Rollout in progress... Checking again in 1 Minute...${RESET}"
            sleep 60
        fi
    done
}

# Run the function
deploy_and_promote

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