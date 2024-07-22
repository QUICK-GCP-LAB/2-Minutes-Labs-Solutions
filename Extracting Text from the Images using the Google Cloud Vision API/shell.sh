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

gsutil mb gs://$DEVSHELL_PROJECT_ID

gsutil mb gs://$DEVSHELL_PROJECT_ID-1

gcloud pubsub topics create my-topic

gcloud pubsub topics create my-topic-1

git clone https://github.com/GoogleCloudPlatform/python-docs-samples.git

cd python-docs-samples/functions/ocr/app/

deploy_function() {
gcloud functions deploy ocr-extract \
--runtime python39 \
--trigger-bucket $DEVSHELL_PROJECT_ID \
--entry-point process_image \
--set-env-vars "^:^GCP_PROJECT=$DEVSHELL_PROJECT_ID:TRANSLATE_TOPIC=my-topic:RESULT_TOPIC=my-topic-1:TO_LANG=es,en,fr,ja"
}

deploy_success=false

while [ "$deploy_success" = false ]; do
  if deploy_function; then
    echo "Cloud Run service is created. Exiting the loop."
    deploy_success=true
  else
    echo "Waiting for Cloud Run service to be created..."
    sleep 60
  fi
done

echo "Running the next code..."

deploy_function() {
gcloud functions deploy ocr-translate \
--runtime python39 \
--trigger-topic my-topic \
--entry-point translate_text \
--set-env-vars "GCP_PROJECT=$DEVSHELL_PROJECT_ID,RESULT_TOPIC=my-topic-1"
}

deploy_success=false

while [ "$deploy_success" = false ]; do
  if deploy_function; then
    echo "Cloud Run service is created. Exiting the loop."
    deploy_success=true
  else
    echo "Waiting for Cloud Run service to be created..."
    sleep 60
  fi
done

echo "Running the next code..."

deploy_function() {
gcloud functions deploy ocr-save \
--runtime python39 \
--trigger-topic my-topic-1 \
--entry-point save_result \
--set-env-vars "GCP_PROJECT=$DEVSHELL_PROJECT_ID,RESULT_BUCKET=$DEVSHELL_PROJECT_ID-1"
}

deploy_success=false

while [ "$deploy_success" = false ]; do
  if deploy_function; then
    echo "Cloud Run service is created. Exiting the loop."
    deploy_success=true
  else
    echo "Waiting for Cloud Run service to be created..."
    sleep 60
  fi
done

echo "Running the next code..."

gsutil cp gs://cloud-training/OCBL307/menu.jpg .

gsutil cp menu.jpg gs://$DEVSHELL_PROJECT_ID

gcloud functions logs read --limit 100

echo "${BG_RED}${BOLD}Congratulations For Completing The Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#
