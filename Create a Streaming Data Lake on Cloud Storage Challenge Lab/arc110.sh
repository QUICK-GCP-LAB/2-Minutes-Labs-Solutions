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
#----------------------------------------------------start--------------------------------------------------#

echo "${BG_MAGENTA}${BOLD}Starting Execution${RESET}"

export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")

export REGION=$(echo "$ZONE" | cut -d '-' -f 1-2)

gcloud config set compute/region $REGION

gcloud services disable dataflow.googleapis.com
gcloud services enable \
dataflow.googleapis.com \
cloudscheduler.googleapis.com

sleep 30

PROJECT_ID=$(gcloud config get-value project)
BUCKET="${PROJECT_ID}-bucket"

gsutil mb gs://$BUCKET

gcloud pubsub topics create $TOPIC

# Set the App Engine region variable
if [ "$REGION" == "us-central1" ]; then
  gcloud app create --region us-central
elif [ "$REGION" == "europe-west1" ]; then
  gcloud app create --region europe-west
else
  gcloud app create --region "$REGION"
fi

gcloud scheduler jobs create pubsub publisher-job --schedule="* * * * *" \
    --topic=$TOPIC --message-body="$MESSAGE"

while true; do
    if gcloud scheduler jobs run publisher-job --location="$REGION"; then
        echo "Command executed successfully. Now running next command.."
        break 
    else
        echo "Retrying please wait..."
        sleep 10 
    fi
done

cat > shell.sh <<EOF_CP
#!/bin/bash
git clone https://github.com/GoogleCloudPlatform/python-docs-samples.git
cd python-docs-samples/pubsub/streaming-analytics
pip install -U -r requirements.txt
python PubSubToGCS.py \
--project=$PROJECT_ID \
--region=$REGION \
--input_topic=projects/$PROJECT_ID/topics/$TOPIC \
--output_path=gs://$BUCKET/samples/output \
--runner=DataflowRunner \
--window_size=2 \
--num_shards=2 \
--temp_location=gs://$BUCKET_NAME/temp
EOF_CP

chmod +x shell.sh

docker run -it -e DEVSHELL_PROJECT_ID=$DEVSHELL_PROJECT_ID -e BUCKET_NAME=$BUCKET -e PROJECT_ID=$PROJECT_ID -e REGION=$REGION -e TOPIC=$TOPIC -v $(pwd)/shell.sh:/shell.sh python:3.7 /bin/bash -c "/shell.sh"

echo "${BG_RED}${BOLD}Congratulations For Completing The Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#