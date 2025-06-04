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

# Step 1: Set Compute Region
echo "${BOLD}${BLUE}Setting Compute Region${RESET}"
export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")

# Step 2: Prepare SQL Instance creation JSON request body
echo "${BOLD}${GREEN}Preparing SQL Instance creation request body${RESET}"
read -r -d '' REQUEST_BODY <<EOF
{
  "name": "my-instance",
  "region": "$REGION",
  "settings": {
    "tier": "db-n1-standard-1"
  }
}
EOF

# Step 3: Create SQL Instance
echo "${BOLD}${YELLOW}Creating SQL Instance${RESET}"
curl -X POST \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  -d "$REQUEST_BODY" \
  "https://sqladmin.googleapis.com/sql/v1beta4/projects/$DEVSHELL_PROJECT_ID/instances"

check_sql_instance_status() {

  while true; do
    status=$(gcloud sql instances describe "my-instance" \
      --project "$DEVSHELL_PROJECT_ID" \
      --format="get(state)")

    echo "${BOLD}${BLUE}Current status: $status${RESET}"

    if [[ "$status" == "RUNNABLE" ]]; then
      echo "${BOLD}${GREEN}Instance is RUNNABLE!${RESET}"
      break
    elif [[ "$status" == "FAILED" || "$status" == "SUSPENDED" ]]; then
      echo "${BOLD}${RED}Instance creation failed or suspended. Status: $status${RESET}"
      break
    fi

    sleep 60
  done
}

# Step 4: Wait for the SQL instance to be RUNNABLE
echo "${BOLD}${CYAN}Waiting for SQL instance to be RUNNABLE...${RESET}"
check_sql_instance_status

# Step 5: Create MySQL Database in the Instance
echo "${BOLD}${MAGENTA}Creating MySQL database 'mysql-db'${RESET}"
curl -X POST \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  -d '{
        "name": "mysql-db"
      }' \
  "https://sqladmin.googleapis.com/sql/v1beta4/projects/$DEVSHELL_PROJECT_ID/instances/my-instance/databases"

# Step 6: Generate unique Cloud Storage bucket name
echo "${BOLD}${CYAN}Generating unique Cloud Storage bucket name${RESET}"
BUCKET_NAME="bucket-$(date +%s)"  # unique name

# Step 7: Get Public IP Address of SQL Instance
echo "${BOLD}${RED}Getting public IP address of SQL Instance${RESET}"
IP_ADDRESS=$(gcloud sql instances describe "my-instance" \
  --format="value(ipAddresses[0].ipAddress)")

if [[ -z "$IP_ADDRESS" ]]; then
  echo "${BOLD}${RED}No public IP found. Enable Public IP on your SQL instance.${RESET}"
  exit 1
fi

# Step 8: Get your current public IP for authorized networks
echo "${BOLD}${GREEN}Getting current public IP address for authorized networks${RESET}"
MY_IP=$(curl -s ifconfig.me)

# Step 9: Authorize your IP on SQL Instance
echo "${BOLD}${YELLOW}Authorizing IP $MY_IP on SQL Instance${RESET}"
gcloud sql instances patch "my-instance" \
  --authorized-networks="$MY_IP/32" --quiet

# Step 10: Create table in the MySQL database
echo "${BOLD}${BLUE}Creating 'info' table in 'mysql-db' database${RESET}"
mysql -h "$IP_ADDRESS" -u root "mysql-db" <<EOF
CREATE TABLE IF NOT EXISTS info (
  name VARCHAR(255),
  age INT,
  occupation VARCHAR(255)
);
EOF

# Step 11: Create CSV file with employee information
echo "${BOLD}${MAGENTA}Creating employee_info.csv file${RESET}"
cat > employee_info.csv <<EOF
"Sean", 23, "Content Creator"
"Emily", 34, "Cloud Engineer"
"Rocky", 40, "Event coordinator"
"Kate", 28, "Data Analyst"
"Juan", 51, "Program Manager"
"Jennifer", 32, "Web Developer"
EOF

# Step 12: Create Cloud Storage bucket
echo "${BOLD}${CYAN}Creating Cloud Storage bucket $BUCKET_NAME${RESET}"
gsutil mb -l "$REGION" -p "$DEVSHELL_PROJECT_ID" gs://"$BUCKET_NAME"

# Step 13: Upload CSV file to the bucket
echo "${BOLD}${RED}Uploading employee_info.csv to gs://$BUCKET_NAME/${RESET}"
gsutil cp employee_info.csv gs://"$BUCKET_NAME"/

# Step 14: Get service account email for the SQL instance
echo "${BOLD}${GREEN}Retrieving service account email for SQL Instance${RESET}"
SERVICE_ACCOUNT=$(gcloud sql instances describe "my-instance" \
  --project="$DEVSHELL_PROJECT_ID" \
  --format="value(serviceAccountEmailAddress)")

if [[ -z "$SERVICE_ACCOUNT" ]]; then
  echo "${BOLD}${RED}Could not find the service account for the SQL instance.${RESET}"
  exit 1
fi

# Step 15: Grant Storage Admin role to SQL instance service account on the bucket
echo "${BOLD}${YELLOW}Granting Storage Admin role to $SERVICE_ACCOUNT on bucket $BUCKET_NAME${RESET}"
gsutil iam ch "serviceAccount:$SERVICE_ACCOUNT:roles/storage.admin" gs://"$BUCKET_NAME"

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
