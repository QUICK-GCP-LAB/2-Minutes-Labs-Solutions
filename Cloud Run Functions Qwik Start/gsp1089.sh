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

# Step 1: Enable necessary Google Cloud services
echo "${BOLD}${CYAN}Enabling required Google Cloud services...${RESET}"
gcloud services enable \
  artifactregistry.googleapis.com \
  cloudfunctions.googleapis.com \
  cloudbuild.googleapis.com \
  eventarc.googleapis.com \
  run.googleapis.com \
  logging.googleapis.com \
  osconfig.googleapis.com \
  pubsub.googleapis.com

# Step 2: Get project ID, Project Number, Zone & Region
echo "${BOLD}${GREEN}Getting Project ID, Project Number, Zone & Region...${RESET}"
export PROJECT_ID=$(gcloud config get-value project)
PROJECT_NUMBER=$(gcloud projects list --filter="project_id:$PROJECT_ID" --format='value(project_number)')
export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")
export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")

# Step 3: Set default compute region
echo "${BOLD}${YELLOW}Setting default compute region...${RESET}"
gcloud config set compute/region $REGION

# Step 4: Get service account for Cloud KMS
echo "${BOLD}${RED}Getting Service Account for Cloud KMS...${RESET}"
SERVICE_ACCOUNT=$(gsutil kms serviceaccount -p $PROJECT_NUMBER)

# Step 5: Assign pubsub.publisher role to service account
echo "${BOLD}${CYAN}Assigning roles/pubsub.publisher to service account...${RESET}"
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member serviceAccount:$SERVICE_ACCOUNT \
  --role roles/pubsub.publisher

# Step 6: Assign eventarc.eventReceiver role to default compute service account
echo "${BOLD}${GREEN}Assigning roles/eventarc.eventReceiver to default compute service account...${RESET}"
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com \
  --role roles/eventarc.eventReceiver

# Step 7: Get IAM policy and store in policy.yaml
echo "${BOLD}${BLUE}Retrieving IAM Policy and saving to policy.yaml...${RESET}"
gcloud projects get-iam-policy $DEVSHELL_PROJECT_ID > policy.yaml

# Step 8: Append audit logging configuration to policy.yaml
echo "${BOLD}${MAGENTA}Configuring audit logging in policy.yaml...${RESET}"
cat <<EOF >> policy.yaml
auditConfigs:
- auditLogConfigs:
  - logType: ADMIN_READ
  - logType: DATA_READ
  - logType: DATA_WRITE
  service: compute.googleapis.com
EOF

# Step 9: Apply updated IAM policy
echo "${BOLD}${RED}Applying updated IAM policy...${RESET}"
gcloud projects set-iam-policy $DEVSHELL_PROJECT_ID policy.yaml

# Step 10: Create and navigate to hello-http directory
echo "${BOLD}${GREEN}Creating hello-http directory and navigating into it...${RESET}"
mkdir ~/hello-http && cd $_

# Step 11: Create index.js file for Cloud Function
echo "${BOLD}${YELLOW}Creating index.js for Node.js Cloud Function...${RESET}"
cat > index.js <<EOF
const functions = require('@google-cloud/functions-framework');

functions.http('helloWorld', (req, res) => {
  res.status(200).send('HTTP with Node.js in GCF 2nd gen!');
});
EOF

# Step 12: Create package.json file
echo "${BOLD}${BLUE}Creating package.json file...${RESET}"
cat > package.json <<EOF
{
  "name": "nodejs-functions-gen2-codelab",
  "version": "0.0.1",
  "main": "index.js",
  "dependencies": {
    "@google-cloud/functions-framework": "^2.0.0"
  }
}
EOF

# Step 13: Deploy Cloud Function
echo "${BOLD}${MAGENTA}Deploying Cloud Function...${RESET}"
deploy_function() {
  while true; do
    echo "Attempting to deploy the Cloud Function..."
    
    gcloud functions deploy nodejs-http-function \
      --gen2 \
      --runtime nodejs22 \
      --entry-point helloWorld \
      --source . \
      --region $REGION \
      --trigger-http \
      --timeout 600s \
      --max-instances 1 \
      --allow-unauthenticated
    
    if [ $? -eq 0 ]; then
      echo "Cloud Function deployed successfully!"
      break
    else
      echo "Deployment failed. Retrying in 30 seconds..."
      sleep 30
    fi
  done
}

# Call the function
deploy_function

# Step 14: Call the deployed function
echo "${BOLD}${RED}Calling Deployed HTTP Cloud Function${RESET}"
gcloud functions call nodejs-http-function \
  --gen2 --region $REGION

# Step 15: Create directory for Storage function and navigate to it
echo "${BOLD}${BLUE}Creating 'hello-storage' Directory and Navigating to it${RESET}"
mkdir ~/hello-storage && cd $_

# Step 16: Create index.js for Storage function
echo "${BOLD}${CYAN}Creating index.js for Storage Function${RESET}"
cat > index.js <<EOF
const functions = require('@google-cloud/functions-framework');

functions.cloudEvent('helloStorage', (cloudevent) => {
  console.log('Cloud Storage event with Node.js in GCF 2nd gen!');
  console.log(cloudevent);
});
EOF

# Step 17: Create package.json for Storage function
echo "${BOLD}${MAGENTA}Creating package.json for Storage Function${RESET}"
cat > package.json <<EOF
{
  "name": "nodejs-functions-gen2-codelab",
  "version": "0.0.1",
  "main": "index.js",
  "dependencies": {
    "@google-cloud/functions-framework": "^2.0.0"
  }
}
EOF

# Step 18: Create a Cloud Storage bucket
echo "${BOLD}${YELLOW}Creating Cloud Storage Bucket${RESET}"
BUCKET="gs://gcf-gen2-storage-$PROJECT_ID"
gsutil mb -l $REGION $BUCKET

# Step 19: Deploy Cloud Function for Storage trigger
echo "${BOLD}${GREEN}Deploying Storage-Triggered Cloud Function${RESET}"
deploy_function() {
  while true; do
    echo "Attempting to deploy the Cloud Function..."
    
gcloud functions deploy nodejs-storage-function \
  --gen2 \
  --runtime nodejs22 \
  --entry-point helloStorage \
  --source . \
  --region $REGION \
  --trigger-bucket $BUCKET \
  --trigger-location $REGION \
  --max-instances 1
    
    if [ $? -eq 0 ]; then
      echo "Cloud Function deployed successfully!"
      break
    else
      echo "Deployment failed. Retrying in 30 seconds..."
      sleep 30
    fi
  done
}

# Call the function
deploy_function

# Step 20: Upload a test file to the Storage bucket
echo "${BOLD}${RED}Uploading Test File to Cloud Storage${RESET}"
echo "Hello World" > random.txt
gsutil cp random.txt $BUCKET/random.txt

# Step 21: Read function logs
echo "${BOLD}${BLUE}Reading Function Logs${RESET}"
gcloud functions logs read nodejs-storage-function \
  --region $REGION --gen2 --limit=100 --format "value(log)"

# Step 22: Navigate to the home directory & Clone the Eventarc samples repository
echo "${BOLD}${YELLOW}Navigating to the home directory & Cloning the Eventarc samples repository...${RESET}"
cd ~
git clone https://github.com/GoogleCloudPlatform/eventarc-samples.git

# Step 23: Change directory to the Node.js function
echo "${BOLD}${GREEN}Changing directory to the Node.js function...${RESET}"
cd ~/eventarc-samples/gce-vm-labeler/gcf/nodejs

# Step 24: Deploy the Cloud Function with retry logic
echo "${BOLD}${MAGENTA}Deploying the Cloud Function (with retries)...${RESET}"
deploy_function() {
  while true; do
    echo "Attempting to deploy the Cloud Function..."
    
gcloud functions deploy gce-vm-labeler \
  --gen2 \
  --runtime nodejs22 \
  --entry-point labelVmCreation \
  --source . \
  --region $REGION \
  --trigger-event-filters="type=google.cloud.audit.log.v1.written,serviceName=compute.googleapis.com,methodName=beta.compute.instances.insert" \
  --trigger-location $REGION \
  --max-instances 1
    
    if [ $? -eq 0 ]; then
      echo "Cloud Function deployed successfully!"
      break
    else
      echo "Deployment failed. Retrying in 30 seconds..."
      sleep 30
    fi
  done
}

# Call the function
deploy_function

# Step 25: Create a Compute Engine instance
echo "${BOLD}${CYAN}Creating a Compute Engine instance...${RESET}"
gcloud compute instances create instance-1 --project=$PROJECT_ID --zone=$ZONE --machine-type=e2-medium --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=default --metadata=enable-osconfig=TRUE,enable-oslogin=true --maintenance-policy=MIGRATE --provisioning-model=STANDARD --service-account=$PROJECT_NUMBER-compute@developer.gserviceaccount.com --scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/trace.append --create-disk=auto-delete=yes,boot=yes,device-name=instance-1,image=projects/debian-cloud/global/images/debian-12-bookworm-v20250311,mode=rw,size=10,type=pd-balanced --no-shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring --labels=goog-ops-agent-policy=v2-x86-template-1-4-0,goog-ec-src=vm_add-gcloud --reservation-affinity=any && printf 'agentsRule:\n  packageState: installed\n  version: latest\ninstanceFilter:\n  inclusionLabels:\n  - labels:\n      goog-ops-agent-policy: v2-x86-template-1-4-0\n' > config.yaml && gcloud compute instances ops-agents policies create goog-ops-agent-v2-x86-template-1-4-0-$ZONE --project=$PROJECT_ID --zone=$ZONE --file=config.yaml && gcloud compute resource-policies create snapshot-schedule default-schedule-1 --project=$PROJECT_ID --region=$REGION --max-retention-days=14 --on-source-disk-delete=keep-auto-snapshots --daily-schedule --start-time=08:00 && gcloud compute disks add-resource-policies instance-1 --project=$PROJECT_ID --zone=$ZONE --resource-policies=projects/$PROJECT_ID/regions/$REGION/resourcePolicies/default-schedule-1

# Step 26: Describe the instance details
echo "${BOLD}${YELLOW}Describing the Compute Engine instance...${RESET}"
gcloud compute instances describe instance-1 --zone $ZONE

# Step 27: Create and enter a directory for the Hello World function
echo "${BOLD}${GREEN}Creating and navigating to the hello-world directory...${RESET}"
mkdir ~/hello-world-colored && cd $_

# Step 28: Create a Python function file
echo "${BOLD}${MAGENTA}Creating the Python function file...${RESET}"
touch requirements.txt
cat > main.py <<EOF
import os

color = os.environ.get('COLOR')

def hello_world(request):
    return f'<body style="background-color:{color}"><h1>Hello World!</h1></body>'
EOF

# Step 29: Deploy the Python function with retries
echo "${BOLD}${CYAN}Deploying the Python Cloud Function (with retries)...${RESET}"
deploy_function() {
  while true; do
    echo "Attempting to deploy the Cloud Function..."
    
COLOR=yellow
gcloud functions deploy hello-world-colored \
  --gen2 \
  --runtime python39 \
  --entry-point hello_world \
  --source . \
  --region $REGION \
  --trigger-http \
  --allow-unauthenticated \
  --update-env-vars COLOR=$COLOR \
  --max-instances 1 \
  --quiet
    
    if [ $? -eq 0 ]; then
      echo "Cloud Function deployed successfully!"
      break
    else
      echo "Deployment failed. Retrying in 30 seconds..."
      sleep 30
    fi
  done
}

# Call the function
deploy_function

# Step 30: Create and navigate to a directory for the Go function
echo "${BOLD}${YELLOW}Creating and navigating to the Go function directory...${RESET}"
mkdir ~/min-instances && cd $_
touch main.go

# Step 31: Create a Go function file
echo "${BOLD}${MAGENTA}Creating the Go function file...${RESET}"
cat > main.go <<EOF_END
package p

import (
        "fmt"
        "net/http"
        "time"
)

func init() {
        time.Sleep(10 * time.Second)
}

func HelloWorld(w http.ResponseWriter, r *http.Request) {
        fmt.Fprint(w, "Slow HTTP Go in GCF 2nd gen!")
}
EOF_END

# Step 32: Create a Go module
echo "${BOLD}${CYAN}Creating the Go module...${RESET}"
echo "module example.com/mod" > go.mod

# Step 33: Deploy the Go function with retries
echo "${BOLD}${GREEN}Deploying the Go Cloud Function (with retries)...${RESET}"
deploy_function() {
  while true; do
    echo "Attempting to deploy the Cloud Function..."
    
gcloud functions deploy slow-function \
  --gen2 \
  --runtime go121 \
  --entry-point HelloWorld \
  --source . \
  --region $REGION \
  --trigger-http \
  --allow-unauthenticated \
  --max-instances 4
    
    if [ $? -eq 0 ]; then
      echo "Cloud Function deployed successfully!"
      break
    else
      echo "Deployment failed. Retrying in 30 seconds..."
      sleep 30
    fi
  done
}

# Call the function
deploy_function

# Step 34: Call the slow-function
echo "${BOLD}${MAGENTA}Calling the slow-function...${RESET}"
gcloud functions call slow-function \
  --gen2 --region $REGION

# Transform DEVSHELL_PROJECT_ID and REGION
export spcl_project=$(echo "$DEVSHELL_PROJECT_ID" | sed 's/-/--/g; s/$/__/g')
export my_region=$(echo "$REGION" | sed 's/-/--/g; s/$/__/g')

# Build the final string
export full_path="$REGION-docker.pkg.dev/$DEVSHELL_PROJECT_ID/gcf-artifacts/$spcl_project$my_region"

# Append the static part
export full_path="${full_path}slow--function:version_1"

# Step 35: Deploy the slow-function to Cloud Run
echo "${BOLD}${CYAN}Deploying the slow-function to Cloud Run...${RESET}"
gcloud run deploy slow-function \
--image=$full_path \
--min-instances=1 \
--max-instances=4 \
--region=$REGION \
--project=$DEVSHELL_PROJECT_ID

# Step 36: Call the slow-function
echo "${BOLD}${YELLOW}Calling the slow-function...${RESET}"
gcloud functions call slow-function \
  --gen2 --region $REGION

# Step 37: Retrieve the function's URL
echo "${BOLD}${GREEN}Retrieving the slow-function URL...${RESET}"
SLOW_URL=$(gcloud functions describe slow-function --region $REGION --gen2 --format="value(serviceConfig.uri)")

# Step 38: Load test the function using hey
echo "${BOLD}${MAGENTA}Running load test on slow-function...${RESET}"
hey -n 10 -c 10 $SLOW_URL

# Function to prompt user to check their progress
function check_progress {
    while true; do
        echo
        echo -n "${BOLD}${YELLOW}Have you checked your progress up to Task 6? (Y/N): ${RESET}"
        read -r user_input
        if [[ "$user_input" == "Y" || "$user_input" == "y" ]]; then
            echo
            echo "${BOLD}${GREEN}Great! Proceeding to the next steps...${RESET}"
            echo
            break
        elif [[ "$user_input" == "N" || "$user_input" == "n" ]]; then
            echo
            echo "${BOLD}${RED}Please check your progress up to Task 6.${RESET}"
        else
            echo
            echo "${BOLD}${MAGENTA}Invalid input. Please enter Y or N.${RESET}"
        fi
    done
}

# Call function to check progress before proceeding
check_progress

# Step 39: Delete the slow-function service from Cloud Run
echo "${BOLD}${RED}Deleting the slow-function service from Cloud Run...${RESET}"
gcloud run services delete slow-function --region $REGION --quiet

# Step 40: Deploy the slow-concurrent-function to Cloud Functions
echo "${BOLD}${CYAN}Deploying the slow-concurrent-function to Cloud Functions...${RESET}"
deploy_function() {
  while true; do
    echo "Attempting to deploy the Cloud Function..."
    
gcloud functions deploy slow-concurrent-function \
  --gen2 \
  --runtime go121 \
  --entry-point HelloWorld \
  --source . \
  --region $REGION \
  --trigger-http \
  --allow-unauthenticated \
  --min-instances 1 \
  --max-instances 4 \
  --quiet
    
    if [ $? -eq 0 ]; then
      echo "Cloud Function deployed successfully!"
      break
    else
      echo "Deployment failed. Retrying in 30 seconds..."
      sleep 30
    fi
  done
}

# Call the function
deploy_function

# Transform DEVSHELL_PROJECT_ID and REGION
export spcl_project=$(echo "$DEVSHELL_PROJECT_ID" | sed 's/-/--/g; s/$/__/g')
export my_region=$(echo "$REGION" | sed 's/-/--/g; s/$/__/g')

# Build the final string
export full_path="$REGION-docker.pkg.dev/$DEVSHELL_PROJECT_ID/gcf-artifacts/$spcl_project$my_region"

# Append the static part
export full_path="${full_path}slow--concurrent--function:version_1"

# Step 41: Deploy slow-concurrent-function to Cloud Run
echo "${BOLD}${GREEN}Deploying slow-concurrent-function to Cloud Run...${RESET}"
gcloud run deploy slow-concurrent-function \
--image=$full_path \
--concurrency=100 \
--cpu=1 \
--max-instances=4 \
--set-env-vars=LOG_EXECUTION_ID=true \
--region=$REGION \
--project=$DEVSHELL_PROJECT_ID \
 && gcloud run services update-traffic slow-concurrent-function --to-latest --region=$REGION

# Step 42: Retrieve the function's URL
echo "${BOLD}${YELLOW}Retrieving the slow-concurrent-function URL...${RESET}"
SLOW_CONCURRENT_URL=$(gcloud functions describe slow-concurrent-function --region $REGION --gen2 --format="value(serviceConfig.uri)")

# Step 43: Load test the function using hey
echo "${BOLD}${MAGENTA}Running load test on slow-concurrent-function...${RESET}"
hey -n 10 -c 10 $SLOW_CONCURRENT_URL

echo

echo "${BOLD}${CYAN}Manage or edit your deployment here: ${RESET}""https://console.cloud.google.com/run/deploy/$REGION/slow-concurrent-function?project=$DEVSHELL_PROJECT_ID"

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
