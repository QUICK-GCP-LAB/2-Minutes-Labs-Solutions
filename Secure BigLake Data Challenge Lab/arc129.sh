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

# Step 1: Fetch taxonomy & plocy details
echo "${BOLD}${CYAN}Fetching taxonomy name, ID & policy...${RESET}"
export TAXONOMY_NAME=$(gcloud data-catalog taxonomies list \
  --location=us \
  --project=$DEVSHELL_PROJECT_ID \
  --format="value(displayName)" \
  --limit=1)

export TAXONOMY_ID=$(gcloud data-catalog taxonomies list \
  --location=us \
  --format="value(name)" \
  --filter="displayName=$TAXONOMY_NAME" | awk -F'/' '{print $6}')

export POLICY_TAG=$(gcloud data-catalog taxonomies policy-tags list \
  --location=us \
  --taxonomy=$TAXONOMY_ID \
  --format="value(name)" \
  --limit=1)

# Step 2: Create BigQuery dataset
echo "${BOLD}${CYAN}Creating the BigQuery dataset...${RESET}"
bq mk online_shop

# Step 3: Create BigQuery connection
echo "${BOLD}${CYAN}Creating a BigQuery connection...${RESET}"
bq mk --connection --location=US --project_id=$DEVSHELL_PROJECT_ID --connection_type=CLOUD_RESOURCE user_data_connection

# Step 4: Grant the service account permission to read Cloud Storage files
echo "${BOLD}${CYAN}Granting service account permissions to read Cloud Storage...${RESET}"
export SERVICE_ACCOUNT=$(bq show --format=json --connection $DEVSHELL_PROJECT_ID.US.user_data_connection | jq -r '.cloudResource.serviceAccountId')

gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
  --member=serviceAccount:$SERVICE_ACCOUNT \
  --role=roles/storage.objectViewer

# Step 5: Create a table definition for the CSV file
echo "${BOLD}${CYAN}Creating BigQuery table definition from Cloud Storage file...${RESET}"
bq mkdef \
--autodetect \
--connection_id=$DEVSHELL_PROJECT_ID.US.user_data_connection \
--source_format=CSV \
"gs://$DEVSHELL_PROJECT_ID-bucket/user-online-sessions.csv" > /tmp/tabledef.json

# Step 6: Create a BigLake table in the dataset
echo "${BOLD}${CYAN}Creating a BigLake table in the BigQuery dataset...${RESET}"
bq mk --external_table_definition=/tmp/tabledef.json \
--project_id=$DEVSHELL_PROJECT_ID \
online_shop.user_online_sessions

# Step 7: Create schema for the table
echo "${BOLD}${CYAN}Creating schema for the BigLake table...${RESET}"
cat > schema.json << EOM
[
  {
    "mode": "NULLABLE",
    "name": "ad_event_id",
    "type": "INTEGER"
  },
  {
    "mode": "NULLABLE",
    "name": "user_id",
    "type": "INTEGER"
  },
  {
    "mode": "NULLABLE",
    "name": "uri",
    "type": "STRING"
  },
  {
    "mode": "NULLABLE",
    "name": "traffic_source",
    "type": "STRING"
  },
  {
    "mode": "NULLABLE",
    "name": "zip",
    "policyTags": {
      "names": [
        "$POLICY_TAG"
      ]
    },
    "type": "STRING"
  },
  {
    "mode": "NULLABLE",
    "name": "event_type",
    "type": "STRING"
  },
  {
    "mode": "NULLABLE",
    "name": "state",
    "type": "STRING"
  },
  {
    "mode": "NULLABLE",
    "name": "country",
    "type": "STRING"
  },
  {
    "mode": "NULLABLE",
    "name": "city",
    "type": "STRING"
  },
  {
    "mode": "NULLABLE",
    "name": "latitude",
    "policyTags": {
      "names": [
        "$POLICY_TAG"
      ]
    },
    "type": "FLOAT"
  },
  {
    "mode": "NULLABLE",
    "name": "created_at",
    "type": "TIMESTAMP"
  },
  {
    "mode": "NULLABLE",
    "name": "ip_address",
    "policyTags": {
      "names": [
        "$POLICY_TAG"
      ]
    },
    "type": "STRING"
  },
  {
    "mode": "NULLABLE",
    "name": "session_id",
    "type": "STRING"
  },
  {
    "mode": "NULLABLE",
    "name": "longitude",
    "policyTags": {
      "names": [
        "$POLICY_TAG"
      ]
    },
    "type": "FLOAT"
  },
  {
    "mode": "NULLABLE",
    "name": "id",
    "type": "INTEGER"
  }
]
EOM

# Step 8: Update the schema for the BigLake table
echo "${BOLD}${CYAN}Updating schema for the 'user_online_sessions' table...${RESET}"
bq update --schema schema.json $DEVSHELL_PROJECT_ID:online_shop.user_online_sessions

# Step 9: Run a query to exclude sensitive information
echo "${BOLD}${CYAN}Running query to exclude sensitive columns...${RESET}"
bq query --use_legacy_sql=false --format=csv \
"SELECT * EXCEPT(zip, latitude, ip_address, longitude) 
FROM \`${DEVSHELL_PROJECT_ID}.online_shop.user_online_sessions\`"

echo

# Step 10: Remove IAM policy binding
echo "${BOLD}${CYAN}Removing IAM policy binding for user $USER_2...${RESET}"
gcloud projects remove-iam-policy-binding ${DEVSHELL_PROJECT_ID} \
  --member="user:$USER_2" \
  --role="roles/storage.objectViewer"

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