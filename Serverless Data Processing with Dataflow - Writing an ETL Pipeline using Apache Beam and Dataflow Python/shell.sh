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

# Step 1: Clone the repository
echo "${GREEN}${BOLD}Cloning the Google Cloud training repository...${RESET}"
git clone https://github.com/GoogleCloudPlatform/training-data-analyst
cd /home/jupyter/training-data-analyst/quests/dataflow_python/

# Step 2: Navigate to lab directory
echo "${YELLOW}${BOLD}Navigating to lab directory...${RESET}"
cd 1_Basic_ETL/lab
export BASE_DIR=$(pwd)

# Step 3: Install Python virtual environment
echo "${BLUE}${BOLD}Installing Python virtual environment...${RESET}"
sudo apt-get update && sudo apt-get install -y python3-venv

# Step 4: Create and activate virtual environment
echo "${MAGENTA}${BOLD}Creating and activating virtual environment...${RESET}"
python3 -m venv df-env

source df-env/bin/activate

# Step 5: Install required Python packages
echo "${RED}${BOLD}Installing required Python packages...${RESET}"
python3 -m pip install -q --upgrade pip setuptools wheel
python3 -m pip install apache-beam[gcp]

# Step 6: Enable Google Cloud Dataflow service
echo "${CYAN}${BOLD}Enabling Google Cloud Dataflow service...${RESET}"
gcloud services enable dataflow.googleapis.com

# Step 7: Download pipeline script
echo "${YELLOW}${BOLD}Downloading Apache Beam pipeline script...${RESET}"
rm my_pipeline.py

curl -LO https://raw.githubusercontent.com/QUICK-GCP-LAB/2-Minutes-Labs-Solutions/refs/heads/main/Serverless%20Data%20Processing%20with%20Dataflow%20-%20Writing%20an%20ETL%20Pipeline%20using%20Apache%20Beam%20and%20Dataflow%20Python/my_pipeline.py

# Step 8: Execute batch scripts
echo "${GREEN}${BOLD}Executing batch scripts...${RESET}"
cd $BASE_DIR/../..

source create_batch_sinks.sh

bash generate_batch_events.sh

head events.json

cd $BASE_DIR

# Step 9: Set Google Cloud project ID & Region
echo "${BLUE}${BOLD}Setting up Google Cloud project ID & Region...${RESET}"
export PROJECT_ID=$(gcloud config get-value project)
export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")

# Step 10: Run the pipeline
echo "${MAGENTA}${BOLD}Running the Apache Beam pipeline...${RESET}"
python3 my_pipeline.py \
  --project=${PROJECT_ID} \
  --region=us-central1 \
  --stagingLocation=gs://$PROJECT_ID/staging/ \
  --tempLocation=gs://$PROJECT_ID/temp/ \
  --runner=DirectRunner

# Step 11: View BigQuery schema
echo "${RED}${BOLD}Viewing BigQuery schema...${RESET}"
cd $BASE_DIR/../..
bq show --schema --format=prettyjson logs.logs

# Step 12: Save schema to JSON file
echo "${CYAN}${BOLD}Saving schema to JSON file...${RESET}"
bq show --schema --format=prettyjson logs.logs | sed '1s/^/{"BigQuery Schema":/' | sed '$s/$/}/' > schema.json

cat schema.json

# Step 13: Upload schema to Cloud Storage
echo "${GREEN}${BOLD}Uploading schema to Cloud Storage...${RESET}"
export PROJECT_ID=$(gcloud config get-value project)
gcloud storage cp schema.json gs://${PROJECT_ID}/

# Step 14: Download JavaScript transformation script
echo "${YELLOW}${BOLD}Downloading JavaScript transformation script...${RESET}"
curl -LO https://raw.githubusercontent.com/QUICK-GCP-LAB/2-Minutes-Labs-Solutions/refs/heads/main/Serverless%20Data%20Processing%20with%20Dataflow%20-%20Writing%20an%20ETL%20Pipeline%20using%20Apache%20Beam%20and%20Dataflow%20Python/transform.js

# Step 15: Upload JavaScript script to Cloud Storage
echo "${BLUE}${BOLD}Uploading JavaScript script to Cloud Storage...${RESET}"
export PROJECT_ID=$(gcloud config get-value project)
gcloud storage cp *.js gs://${PROJECT_ID}/

# Step 16: Run Dataflow job
echo "${MAGENTA}${BOLD}Running Google Cloud Dataflow job...${RESET}"
gcloud dataflow jobs run quickgcplab \
    --gcs-location gs://dataflow-templates-$REGION/latest/GCS_Text_to_BigQuery \
    --region $REGION \
    --staging-location gs://$PROJECT_ID/temp \
    --parameters inputFilePattern=gs://$PROJECT_ID/events.json,JSONPath=gs://$PROJECT_ID/schema.json,outputTable=$PROJECT_ID:logs.logs,bigQueryLoadingTemporaryDirectory=gs://$PROJECT_ID/temp_dir,javascriptTextTransformGcsPath=gs://$PROJECT_ID/transform.js,javascriptTextTransformFunctionName=transform

echo

echo "${BLUE}${BOLD}Click here to view Dataflow job: ${RESET}""https://console.cloud.google.com/dataflow/jobs?project=$PROJECT_ID"

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
