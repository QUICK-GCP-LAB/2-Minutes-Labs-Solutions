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

echo "${YELLOW}${BOLD}Starting${RESET}" "${GREEN}${BOLD}Execution${RESET}"

export PROJECT_ID=$(gcloud config get-value project)

gsutil mb gs://$PROJECT_ID

bq mk $DATASET

bq mk --table \
$PROJECT_ID:$DATASET.$TABLE \
data:string

gcloud pubsub topics create $TOPIC

gcloud pubsub subscriptions create $TOPIC-sub --topic=$TOPIC

gcloud dataflow flex-template run $JOB --region $REGION \
--template-file-gcs-location gs://dataflow-templates-$REGION/latest/flex/PubSub_to_BigQuery_Flex \
--temp-location gs://$PROJECT_ID/temp/ \
--parameters outputTableSpec=$PROJECT_ID:$DATASET.$TABLE,\
inputTopic=projects/$PROJECT_ID/topics/$TOPIC,\
outputDeadletterTable=$PROJECT_ID:$DATASET.$TABLE,\
javascriptTextTransformReloadIntervalMinutes=0,\
useStorageWriteApi=false,\
useStorageWriteApiAtLeastOnce=false,\
numStorageWriteApiStreams=0

#!/bin/bash

while true; do
    STATUS=$(gcloud dataflow jobs list --region="$REGION" --format='value(STATE)' | grep Running)
    
    if [ "$STATUS" == "Running" ]; then
        echo "The Dataflow job is running successfully"

        sleep 20
        gcloud pubsub topics publish $TOPIC --message='{"data": "73.4 F"}'

        bq query --nouse_legacy_sql "SELECT * FROM \`$DEVSHELL_PROJECT_ID.$DATASET.$TABLE\`"
        break
    else
        sleep 30
        echo "The Dataflow job is not running please wait..."
    fi
done

gcloud dataflow jobs run $JOB-quickgcplab --gcs-location gs://dataflow-templates-$REGION/latest/PubSub_to_BigQuery --region=$REGION --project=$PROJECT_ID --staging-location gs://$PROJECT_ID/temp --parameters inputTopic=projects/$PROJECT_ID/topics/$TOPIC,outputTableSpec=$PROJECT_ID:$DATASET.$TABLE

while true; do
    STATUS=$(gcloud dataflow jobs list --region=$REGION --project=$PROJECT_ID --filter="name:$JOB-quickgcplab AND state:Running" --format="value(state)")
    
    if [ "$STATUS" == "Running" ]; then
        echo "The Dataflow job is running successfully"

        sleep 20
        gcloud pubsub topics publish $TOPIC --message='{"data": "73.4 F"}'

        bq query --nouse_legacy_sql "SELECT * FROM \`$PROJECT_ID.$DATASET.$TABLE\`"
        break
    else
        sleep 30
        echo "The Dataflow job is not running please wait..."
    fi
done

echo "${RED}${BOLD}Congratulations${RESET}" "${WHITE}${BOLD}for${RESET}" "${GREEN}${BOLD}Completing the Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#