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

COLORS=($CYAN $GREEN $YELLOW $BLUE $MAGENTA $CYAN)

#----------------------------------------------------start--------------------------------------------------#

echo "${RANDOM_BG_COLOR}${RANDOM_TEXT_COLOR}${BOLD}Starting Execution${RESET}"

echo

# Function to get input from the user with different colors
get_input() {
    local prompt="$1"
    local var_name="$2"
    local color_index="$3"

    echo -n -e "${BOLD}${COLORS[$color_index]}${prompt}${RESET} "
    read input
    export "$var_name"="$input"
}

# Gather inputs for the required variables, cycling through colors
get_input "Enter the DATASET value:" "DATASET" 0
get_input "Enter the BUCKET value:" "BUCKET" 1
get_input "Enter the TABLE value:" "TABLE" 2
get_input "Enter the BUCKET_URL_1 value:" "BUCKET_URL_1" 3
get_input "Enter the BUCKET_URL_2 value:" "BUCKET_URL_2" 4

echo

# Step 1: Enable API keys service
echo "${BLUE}${BOLD}Enabling API keys service...${RESET}"
gcloud services enable apikeys.googleapis.com

# Step 2: Create an API key
echo "${GREEN}${BOLD}Creating an API key with display name 'awesome'...${RESET}"
gcloud alpha services api-keys create --display-name="awesome" 

# Step 3: Retrieve API key name
echo "${YELLOW}${BOLD}Retrieving API key name...${RESET}"
KEY_NAME=$(gcloud alpha services api-keys list --format="value(name)" --filter "displayName=awesome")

# Step 4: Get API key string
echo "${MAGENTA}${BOLD}Getting API key string...${RESET}"
API_KEY=$(gcloud alpha services api-keys get-key-string $KEY_NAME --format="value(keyString)")

# Step 5: Get default Google Cloud region
echo "${CYAN}${BOLD}Getting default Google Cloud region...${RESET}"
export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")

# Step 6: Retrieve project ID
echo "${RED}${BOLD}Retrieving project ID...${RESET}"
PROJECT_ID=$(gcloud config get-value project)

# Step 7: Retrieve project number
echo "${GREEN}${BOLD}Retrieving project number...${RESET}"
PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format="json" | jq -r '.projectNumber')

# Step 8: Create BigQuery dataset
echo "${BLUE}${BOLD}Creating BigQuery dataset...${RESET}"
bq mk $DATASET

# Step 9: Create Cloud Storage bucket
echo "${MAGENTA}${BOLD}Creating Cloud Storage bucket...${RESET}"
gsutil mb gs://$BUCKET

# Step 10: Copy lab files from GCS
echo "${YELLOW}${BOLD}Copying lab files from GCS...${RESET}"
gsutil cp gs://cloud-training/gsp323/lab.csv  .
gsutil cp gs://cloud-training/gsp323/lab.schema .

# Step 11: Display schema contents
echo "${CYAN}${BOLD}Displaying schema contents...${RESET}"
cat lab.schema

echo '[
    {"type":"STRING","name":"guid"},
    {"type":"BOOLEAN","name":"isActive"},
    {"type":"STRING","name":"firstname"},
    {"type":"STRING","name":"surname"},
    {"type":"STRING","name":"company"},
    {"type":"STRING","name":"email"},
    {"type":"STRING","name":"phone"},
    {"type":"STRING","name":"address"},
    {"type":"STRING","name":"about"},
    {"type":"TIMESTAMP","name":"registered"},
    {"type":"FLOAT","name":"latitude"},
    {"type":"FLOAT","name":"longitude"}
]' > lab.schema

# Step 12: Create BigQuery table
echo "${RED}${BOLD}Creating BigQuery table...${RESET}"
bq mk --table $DATASET.$TABLE lab.schema

# Step 13: Run Dataflow job to load data into BigQuery
echo "${GREEN}${BOLD}Running Dataflow job to load data into BigQuery...${RESET}"
gcloud dataflow jobs run awesome-jobs --gcs-location gs://dataflow-templates-$REGION/latest/GCS_Text_to_BigQuery --region $REGION --worker-machine-type e2-standard-2 --staging-location gs://$DEVSHELL_PROJECT_ID-marking/temp --parameters inputFilePattern=gs://cloud-training/gsp323/lab.csv,JSONPath=gs://cloud-training/gsp323/lab.schema,outputTable=$DEVSHELL_PROJECT_ID:$DATASET.$TABLE,bigQueryLoadingTemporaryDirectory=gs://$DEVSHELL_PROJECT_ID-marking/bigquery_temp,javascriptTextTransformGcsPath=gs://cloud-training/gsp323/lab.js,javascriptTextTransformFunctionName=transform

# Step 14: Grant IAM roles to service account
echo "${BLUE}${BOLD}Granting IAM roles to service account...${RESET}"
gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
    --member "serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com" \
    --role "roles/storage.admin"

# Step 15: Assign IAM roles to user
echo "${MAGENTA}${BOLD}Assigning roles to user...${RESET}"
gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
  --member=user:$USER_EMAIL \
  --role=roles/dataproc.editor

gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
  --member=user:$USER_EMAIL \
  --role=roles/storage.objectViewer

# Step 16: Update VPC subnet for private IP access
echo "${CYAN}${BOLD}Updating VPC subnet for private IP access...${RESET}"
gcloud compute networks subnets update default \
    --region $REGION \
    --enable-private-ip-google-access

# Step 17: Create a service account
echo "${RED}${BOLD}Creating a service account...${RESET}"
gcloud iam service-accounts create awesome \
  --display-name "my natural language service account"

sleep 15

# Step 18: Generate service account key
echo "${GREEN}${BOLD}Generating service account key...${RESET}"
gcloud iam service-accounts keys create ~/key.json \
  --iam-account awesome@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com

sleep 15

# Step 19: Activate service account
echo "${YELLOW}${BOLD}Activating service account...${RESET}"
export GOOGLE_APPLICATION_CREDENTIALS="/home/$USER/key.json"

sleep 30

gcloud auth activate-service-account awesome@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com --key-file=$GOOGLE_APPLICATION_CREDENTIALS

# Step 20: Run ML entity analysis
echo "${BLUE}${BOLD}Running ML entity analysis...${RESET}"
gcloud ml language analyze-entities --content="Old Norse texts portray Odin as one-eyed and long-bearded, frequently wielding a spear named Gungnir and wearing a cloak and a broad hat." > result.json

# Step 21: Authenticate to Google Cloud without launching a browser
echo "${GREEN}${BOLD}Authenticating to Google Cloud...${RESET}"
echo
gcloud auth login --no-launch-browser --quiet

# Step 22: Copy result to bucket
echo "${MAGENTA}${BOLD}Copying result to bucket...${RESET}"
gsutil cp result.json $BUCKET_URL_2

cat > request.json <<EOF
{
  "config": {
      "encoding":"FLAC",
      "languageCode": "en-US"
  },
  "audio": {
      "uri":"gs://cloud-training/gsp323/task3.flac"
  }
}
EOF

# Step 23: Perform speech recognition using Google Cloud Speech-to-Text API
echo "${CYAN}${BOLD}Performing speech recognition...${RESET}"
curl -s -X POST -H "Content-Type: application/json" --data-binary @request.json \
"https://speech.googleapis.com/v1/speech:recognize?key=${API_KEY}" > result.json

# Step 24: Copy the speech recognition result to a Cloud Storage bucket
echo "${GREEN}${BOLD}Copying speech recognition result to Cloud Storage...${RESET}"
gsutil cp result.json $BUCKET_URL_1

# Step 25: Create a new service account named 'quickstart'
echo "${MAGENTA}${BOLD}Creating new service account 'quickstart'...${RESET}"
gcloud iam service-accounts create quickstart

sleep 15

# Step 26: Create a service account key for 'quickstart'
echo "${BLUE}${BOLD}Creating service account key...${RESET}"
gcloud iam service-accounts keys create key.json --iam-account quickstart@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com

sleep 15

# Step 27: Authenticate using the created service account key
echo "${CYAN}${BOLD}Activating service account...${RESET}"
gcloud auth activate-service-account --key-file key.json

# Step 28: Create a request JSON file for Video Intelligence API
echo "${GREEN}${BOLD}Creating request JSON file for Video Intelligence API...${RESET}"
cat > request.json <<EOF 
{
   "inputUri":"gs://spls/gsp154/video/train.mp4",
   "features": [
       "TEXT_DETECTION"
   ]
}
EOF

# Step 29: Annotate the video using Google Cloud Video Intelligence API
echo "${MAGENTA}${BOLD}Sending video annotation request...${RESET}"
curl -s -H 'Content-Type: application/json' \
    -H "Authorization: Bearer $(gcloud auth print-access-token)" \
    'https://videointelligence.googleapis.com/v1/videos:annotate' \
    -d @request.json

# Step 30: Retrieve the results of the video annotation
echo "${BLUE}${BOLD}Retrieving video annotation results...${RESET}"
curl -s -H 'Content-Type: application/json' -H "Authorization: Bearer $ACCESS_TOKEN" 'https://videointelligence.googleapis.com/v1/operations/OPERATION_FROM_PREVIOUS_REQUEST' > result1.json

sleep 30

# Step 31: Perform speech recognition again
echo "${CYAN}${BOLD}Performing speech recognition again...${RESET}"
curl -s -X POST -H "Content-Type: application/json" --data-binary @request.json \
"https://speech.googleapis.com/v1/speech:recognize?key=${API_KEY}" > result.json

# Step 32: Annotate the video again using Google Cloud Video Intelligence API
echo "${GREEN}${BOLD}Sending another video annotation request...${RESET}"
curl -s -H 'Content-Type: application/json' \
    -H "Authorization: Bearer $(gcloud auth print-access-token)" \
    'https://videointelligence.googleapis.com/v1/videos:annotate' \
    -d @request.json

# Step 33: Retrieve the new video annotation results
echo "${MAGENTA}${BOLD}Retrieving new video annotation results...${RESET}"
curl -s -H 'Content-Type: application/json' -H "Authorization: Bearer $ACCESS_TOKEN" 'https://videointelligence.googleapis.com/v1/operations/OPERATION_FROM_PREVIOUS_REQUEST' > result1.json

# Function to prompt user to check their progress
function check_progress {
    while true; do
        echo
        echo -n "${BOLD}${YELLOW}Have you checked your progress for Task 3 & Task 4? (Y/N): ${RESET}"
        read -r user_input
        if [[ "$user_input" == "Y" || "$user_input" == "y" ]]; then
            echo
            echo "${BOLD}${GREEN}Great! Proceeding to the next steps...${RESET}"
            echo
            break
        elif [[ "$user_input" == "N" || "$user_input" == "n" ]]; then
            echo
            echo "${BOLD}${RED}Please check your progress for Task 3 & Task 4 and then press Y to continue.${RESET}"
        else
            echo
            echo "${BOLD}${MAGENTA}Invalid input. Please enter Y or N.${RESET}"
        fi
    done
}

# Call function to check progress before proceeding
check_progress

# Step 34: Authenticate to Google Cloud without launching a browser
echo "${GREEN}${BOLD}Authenticating to Google Cloud...${RESET}"
echo
gcloud auth login --no-launch-browser --quiet

# Step 35: Create a new Dataproc cluster
echo "${CYAN}${BOLD}Creating Dataproc cluster...${RESET}"
gcloud dataproc clusters create awesome --enable-component-gateway --region $REGION --master-machine-type e2-standard-2 --master-boot-disk-type pd-balanced --master-boot-disk-size 100 --num-workers 2 --worker-machine-type e2-standard-2 --worker-boot-disk-type pd-balanced --worker-boot-disk-size 100 --image-version 2.2-debian12 --project $DEVSHELL_PROJECT_ID

# Step 36: Get the VM instance name from the project
echo "${GREEN}${BOLD}Fetching VM instance name...${RESET}"
VM_NAME=$(gcloud compute instances list --project="$DEVSHELL_PROJECT_ID" --format=json | jq -r '.[0].name')

# Step 37: Get the compute zone of the VM
echo "${MAGENTA}${BOLD}Fetching VM zone...${RESET}"
export ZONE=$(gcloud compute instances list $VM_NAME --format 'csv[no-heading](zone)')

# Step 48: Copy data from Cloud Storage to HDFS in the VM
echo "${BLUE}${BOLD}Copying data to HDFS on VM...${RESET}"
gcloud compute ssh --zone "$ZONE" "$VM_NAME" --project "$DEVSHELL_PROJECT_ID" --quiet --command="hdfs dfs -cp gs://cloud-training/gsp323/data.txt /data.txt"

# Step 39: Copy data from Cloud Storage to local storage in the VM
echo "${CYAN}${BOLD}Copying data to local storage on VM...${RESET}"
gcloud compute ssh --zone "$ZONE" "$VM_NAME" --project "$DEVSHELL_PROJECT_ID" --quiet --command="gsutil cp gs://cloud-training/gsp323/data.txt /data.txt"

# Step 40: Submit a Spark job to the Dataproc cluster
echo "${MAGENTA}${BOLD}Submitting Spark job to Dataproc...${RESET}"
gcloud dataproc jobs submit spark \
  --cluster=awesome \
  --region=$REGION \
  --class=org.apache.spark.examples.SparkPageRank \
  --jars=file:///usr/lib/spark/examples/jars/spark-examples.jar \
  --project=$DEVSHELL_PROJECT_ID \
  -- /data.txt

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