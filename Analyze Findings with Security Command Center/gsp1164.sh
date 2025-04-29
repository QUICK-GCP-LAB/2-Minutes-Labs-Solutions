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

# Step 1: Get Project ID
echo "${BOLD}${CYAN}Getting Project ID, Zone & Region${RESET}"
export PROJECT_ID=$(gcloud config get project)

export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")

export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")

export BUCKET_NAME="scc-export-bucket-$PROJECT_ID"

# Step 2: Create Pub/Sub Topic
echo "${BOLD}${YELLOW}Creating Pub/Sub Topic${RESET}"
gcloud pubsub topics create projects/$DEVSHELL_PROJECT_ID/topics/export-findings-pubsub-topic

# Step 3: Create Pub/Sub Subscription
echo "${BOLD}${MAGENTA}Creating Pub/Sub Subscription${RESET}"
gcloud pubsub subscriptions create export-findings-pubsub-topic-sub --topic=projects/$DEVSHELL_PROJECT_ID/topics/export-findings-pubsub-topic

echo

# Step 4: Open Console URL for Manual Step
echo "${BOLD}${BLUE}Please open the URL to create export-findings-pubsub: ${RESET}""https://console.cloud.google.com/security/command-center/config/continuous-exports/pubsub?project=$DEVSHELL_PROJECT_ID"

# Function to prompt user to check their progress
function check_progress {
    while true; do
        echo
        echo -n "${BOLD}${YELLOW}Have you created ${WHITE}export-findings-pubsub${YELLOW} ? (Y/N): ${RESET}"
        read -r user_input
        if [[ "$user_input" == "Y" || "$user_input" == "y" ]]; then
            echo
            echo "${BOLD}${GREEN}Great! Proceeding to the next steps...${RESET}"
            echo
            break
        elif [[ "$user_input" == "N" || "$user_input" == "n" ]]; then
            echo
            echo "${BOLD}${RED}Please create ${WHITE}export-findings-pubsub${RED} and then press Y to continue.${RESET}"
        else
            echo
            echo "${BOLD}${MAGENTA}Invalid input. Please enter Y or N.${RESET}"
        fi
    done
}

# Call function to check progress before proceeding
check_progress

# Step 5: Create Compute Instance
echo "${BOLD}${BLUE}Creating Compute Instance${RESET}"
gcloud compute instances create instance-1 --zone=$ZONE \
--machine-type e2-micro \
--scopes=https://www.googleapis.com/auth/cloud-platform

# Step 6: Create BigQuery Dataset
echo "${BOLD}${CYAN}Creating BigQuery Dataset${RESET}"
bq --location=$REGION --apilog=/dev/null mk --dataset \
$PROJECT_ID:continuous_export_dataset

check_and_enable_securitycenter() {
  echo "${BOLD}${BLUE}Checking if Security Center API is already enabled...${RESET}"
  is_enabled=$(gcloud services list --enabled --filter="securitycenter.googleapis.com" --format="value(NAME)" 2>/dev/null)

  if [ "$is_enabled" == "securitycenter.googleapis.com" ]; then
    # If the API is enabled, do nothing and suppress output
    echo "${BOLD}${CYAN}Security Center API is already enabled.${RESET}"
  else
    # Enabling Security Center API quietly
    echo "${BOLD}${RED}Security Center API is not enabled. Enabling now...${RESET}"
    gcloud services enable securitycenter.googleapis.com --quiet >/dev/null 2>&1

    # Wait until the API is enabled
    echo "${BOLD}${MAGENTA}Waiting for Security Center API to be enabled...${RESET}"
    while true; do
      is_enabled=$(gcloud services list --enabled --filter="securitycenter.googleapis.com" --format="value(NAME)" 2>/dev/null)
      if [ "$is_enabled" == "securitycenter.googleapis.com" ]; then
        echo "${BOLD}${GREEN}Security Center API has been enabled successfully.${RESET}"
        break
      fi
      # Wait before checking again
      echo "${BOLD}${RED}Still waiting for API to be enabled... checking again in 5 seconds.${RESET}"
    done
  fi
}

check_and_enable_securitycenter

# Step 7: Create SCC BigQuery Export
echo "${BOLD}${MAGENTA}Creating SCC BigQuery Export${RESET}"
gcloud scc bqexports create scc-bq-cont-export --dataset=projects/$PROJECT_ID/datasets/continuous_export_dataset --project=$PROJECT_ID --quiet

# Step 8: Create Service Accounts and Keys
echo "${BOLD}${YELLOW}Creating Service Accounts and Keys${RESET}"
for i in {0..2}; do
gcloud iam service-accounts create sccp-test-sa-$i;
gcloud iam service-accounts keys create /tmp/sa-key-$i.json \
--iam-account=sccp-test-sa-$i@$PROJECT_ID.iam.gserviceaccount.com;
done

function wait_for_findings() {
  while true; do
    echo "${BOLD}${CYAN}Running query to check for findings...${RESET}"
    result=$(bq query --apilog=/dev/null --use_legacy_sql=false --format=pretty \
      "SELECT finding_id, event_time, finding.category FROM continuous_export_dataset.findings")

    # Check if result contains any rows excluding headers and formatting lines
    if echo "$result" | grep -qE '^[|] [a-f0-9]{32} '; then
      echo "${BOLD}${GREEN}Findings detected!${RESET}"
      echo "$result"
      break
    else
      echo "${BOLD}${YELLOW}No findings yet. Waiting for 2 minutes...${RESET}"
      sleep 120
    fi
  done
}

wait_for_findings

# Step 9: Create Storage Bucket
echo "${BOLD}${BLUE}Creating Storage Bucket${RESET}"
gsutil mb -l $REGION gs://$BUCKET_NAME/

# Step 10: Enforce Public Access Prevention on Bucket
echo "${BOLD}${MAGENTA}Enforcing Public Access Prevention on Bucket${RESET}"
gsutil pap set enforced gs://$BUCKET_NAME

sleep 15

# Step 11: Export Findings to JSONL
echo "${BOLD}${CYAN}Exporting Findings to JSONL${RESET}"
gcloud scc findings list "projects/$PROJECT_ID" \
  --format=json \
  | jq -c '.[]' \
  > findings.jsonl

sleep 15

# Step 12: Upload JSONL to Bucket
echo "${BOLD}${YELLOW}Uploading findings.jsonl to Storage Bucket${RESET}"
gsutil cp findings.jsonl gs://$BUCKET_NAME/

echo

# Step 13: Open BigQuery Console
echo "${BOLD}${GREEN}Open BigQuery Console to create ${WHITE}old_findings${GREEN} table:${RESET}" "https://console.cloud.google.com/bigquery?project=$DEVSHELL_PROJECT_ID"

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