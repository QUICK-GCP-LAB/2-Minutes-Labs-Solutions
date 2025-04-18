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

# Step 1: Set environment variables
echo "${BOLD}${GREEN}Setting environment variables${RESET}"
export PROCESSOR_NAME=form-processor
export PROJECT_ID=$(gcloud config get-value core/project)
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")
export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")

export GEO_CODE_REQUEST_PUBSUB_TOPIC=geocode_request
export BUCKET_LOCATION=$REGION

# Step 2: Create GCS buckets
echo "${BOLD}${YELLOW}Creating GCS buckets${RESET}"
gsutil mb -c standard -l ${BUCKET_LOCATION} -b on \
  gs://${PROJECT_ID}-input-invoices
gsutil mb -c standard -l ${BUCKET_LOCATION} -b on \
  gs://${PROJECT_ID}-output-invoices
gsutil mb -c standard -l ${BUCKET_LOCATION} -b on \
  gs://${PROJECT_ID}-archived-invoices

# Step 3: Enable required services
echo "${BOLD}${BLUE}Enabling required services${RESET}"
gcloud services enable documentai.googleapis.com
gcloud services enable cloudfunctions.googleapis.com
gcloud services enable cloudbuild.googleapis.com
gcloud services enable geocoding-backend.googleapis.com

# Step 4: Create API key
echo "${BOLD}${MAGENTA}Creating API key${RESET}"
gcloud alpha services api-keys create --display-name="awesome" 

# Step 5: Get API key name and string
echo "${BOLD}${CYAN}Retrieving API key string${RESET}"
export KEY_NAME=$(gcloud alpha services api-keys list --format="value(name)" --filter "displayName=awesome")

export API_KEY=$(gcloud alpha services api-keys get-key-string $KEY_NAME --format="value(keyString)")

# Step 6: Restrict API key usage
echo "${BOLD}${RED}Restricting API key usage${RESET}"
curl -X PATCH \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  -d '{
    "restrictions": {
      "apiTargets": [
        {
          "service": "geocoding-backend.googleapis.com"
        }
      ]
    }
  }' \
  "https://apikeys.googleapis.com/v2/$KEY_NAME?updateMask=restrictions"

# Step 7: Copy demo assets
echo "${BOLD}${GREEN}Copying demo assets${RESET}"
mkdir ./documentai-pipeline-demo
gcloud storage cp -r \
  gs://spls/gsp927/documentai-pipeline-demo/* \
  ~/documentai-pipeline-demo/

# Step 8: Create Document AI Processor
echo "${BOLD}${YELLOW}Creating Document AI Processor${RESET}"
curl -X POST \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  -d '{
    "display_name": "'"$PROCESSOR_NAME"'",
    "type": "FORM_PARSER_PROCESSOR"
  }' \
  "https://documentai.googleapis.com/v1/projects/$PROJECT_ID/locations/us/processors"

# Step 9: Create BigQuery dataset and tables
echo "${BOLD}${BLUE}Creating BigQuery dataset and tables${RESET}"
bq --location="US" mk  -d \
    --description "Form Parser Results" \
    ${PROJECT_ID}:invoice_parser_results
cd ~/documentai-pipeline-demo/scripts/table-schema/
bq mk --table \
  invoice_parser_results.doc_ai_extracted_entities \
  doc_ai_extracted_entities.json
bq mk --table \
  invoice_parser_results.geocode_details \
  geocode_details.json

# Step 10: Create Pub/Sub topic
echo "${BOLD}${MAGENTA}Creating Pub/Sub topic${RESET}"
gcloud pubsub topics \
  create ${GEO_CODE_REQUEST_PUBSUB_TOPIC}

# Step 11: Create service account and assign roles
echo "${BOLD}${CYAN}Creating service account and assigning roles${RESET}"
gcloud iam service-accounts create "service-$PROJECT_NUMBER" \
  --display-name "Cloud Storage Service Account" || true

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:service-$PROJECT_NUMBER@gs-project-accounts.iam.gserviceaccount.com" \
  --role="roles/pubsub.publisher"
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:service-$PROJECT_NUMBER@gs-project-accounts.iam.gserviceaccount.com" \
  --role="roles/iam.serviceAccountTokenCreator"

# Step 12: Change to scripts directory
echo "${BOLD}${RED}Changing to scripts directory${RESET}"
  cd ~/documentai-pipeline-demo/scripts
  export CLOUD_FUNCTION_LOCATION=$REGION

# Step 13: Deploy `process-invoices` Cloud Function with retry
echo "${BOLD}${GREEN}Deploying Cloud Function: process-invoices (retry loop)${RESET}"
deploy_function_until_success() {
while true; do
    echo "${BOLD}${YELLOW}Attempting to deploy process-invoices...${RESET}"
    gcloud functions deploy process-invoices \
      --no-gen2 \
      --region="${CLOUD_FUNCTION_LOCATION}" \
      --entry-point=process_invoice \
      --runtime=python39 \
      --source=cloud-functions/process-invoices \
      --timeout=400 \
      --env-vars-file=cloud-functions/process-invoices/.env.yaml \
      --trigger-resource="gs://${PROJECT_ID}-input-invoices" \
      --trigger-event=google.storage.object.finalize

    if [ $? -eq 0 ]; then
      echo "${BOLD}${BLUE}✅ Cloud Function deployed successfully!${RESET}"
      break
    else
      echo "${BOLD}${RED}❌ Deployment failed. Retrying in a few seconds...${RESET}"
      sleep 30
    fi
  done
}

deploy_function_until_success

# Step 14: Deploy `geocode-addresses` Cloud Function with retry
echo "${BOLD}${MAGENTA}Deploying Cloud Function: geocode-addresses (retry loop)${RESET}"
deploy_geocode_addresses_until_success() {
  while true; do
    echo "${BOLD}${CYAN}Attempting to deploy geocode-addresses...${RESET}"

    gcloud functions deploy geocode-addresses \
      --no-gen2 \
      --region="${CLOUD_FUNCTION_LOCATION}" \
      --entry-point=process_address \
      --runtime=python39 \
      --source=cloud-functions/geocode-addresses \
      --timeout=60 \
      --env-vars-file=cloud-functions/geocode-addresses/.env.yaml \
      --trigger-topic="${GEO_CODE_REQUEST_PUBSUB_TOPIC}"

    if [ $? -eq 0 ]; then
      echo "${BOLD}${GREEN}✅ Cloud Function deployed successfully!${RESET}"
      break
    else
      echo "${BOLD}${RED}❌ Deployment failed. Retrying in a few seconds...${RESET}"
      sleep 30
    fi
  done
}

deploy_geocode_addresses_until_success

# Step 15: Get Document AI Processor ID
echo "${BOLD}${YELLOW}Getting Document AI Processor ID${RESET}"
PROCESSOR_ID=$(curl -X GET \
  -H "Authorization: Bearer $(gcloud auth application-default print-access-token)" \
  -H "Content-Type: application/json" \
  "https://documentai.googleapis.com/v1/projects/$PROJECT_ID/locations/us/processors" | \
  grep '"name":' | \
  sed -E 's/.*"name": "projects\/[0-9]+\/locations\/us\/processors\/([^"]+)".*/\1/')

export PROCESSOR_ID

# Step 16: Re-deploy `process-invoices` with updated env vars
echo "${BOLD}${BLUE}Re-deploying process-invoices with updated environment variables${RESET}"
gcloud functions deploy process-invoices \
      --no-gen2 \
      --region="${CLOUD_FUNCTION_LOCATION}" \
      --entry-point=process_invoice \
      --runtime=python39 \
      --source=cloud-functions/process-invoices \
      --timeout=400 \
      --update-env-vars=PROCESSOR_ID=${PROCESSOR_ID},PARSER_LOCATION=us,GCP_PROJECT=${PROJECT_ID} \
      --trigger-resource=gs://${PROJECT_ID}-input-invoices \
      --trigger-event=google.storage.object.finalize

# Step 17: Re-deploy `geocode-addresses` with updated env vars
echo "${BOLD}${MAGENTA}Re-deploying geocode-addresses with updated environment variables${RESET}"
gcloud functions deploy geocode-addresses \
      --no-gen2 \
      --region="${CLOUD_FUNCTION_LOCATION}" \
      --entry-point=process_address \
      --runtime=python39 \
      --source=cloud-functions/geocode-addresses \
      --timeout=60 \
      --update-env-vars=API_key=${API_KEY} \
      --trigger-topic=${GEO_CODE_REQUEST_PUBSUB_TOPIC}

# Step 18: Upload sample files to bucket
echo "${BOLD}${CYAN}Uploading sample files to input bucket${RESET}"
gsutil cp gs://spls/gsp927/documentai-pipeline-demo/sample-files/* gs://${PROJECT_ID}-input-invoices/

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