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

export GEO_CODE_REQUEST_PUBSUB_TOPIC=geocode_request
export PROCESSOR_NAME=form-parser
export PROJECT_ID=$(gcloud config get-value core/project)
ACCESS_TOKEN=$(gcloud auth application-default print-access-token)

KEY_NAME=$(gcloud alpha services api-keys list --format="value(name)" --filter "displayName=awesome")

export API_KEY=$(gcloud alpha services api-keys get-key-string $KEY_NAME --format="value(keyString)")

  mkdir ./documentai-pipeline-demo
  gsutil -m cp -r \
    gs://sureskills-lab-dev/gsp927/documentai-pipeline-demo/* \
    ~/documentai-pipeline-demo/

curl -X POST \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "display_name": "'"$PROCESSOR_NAME"'",
    "type": "FORM_PARSER_PROCESSOR"
  }' \
  "https://documentai.googleapis.com/v1/projects/$PROJECT_ID/locations/us/processors"

gsutil mb -c standard -l ${LOCATION} -b on \
    gs://${PROJECT_ID}-input-invoices
gsutil mb -c standard -l ${LOCATION} -b on \
    gs://${PROJECT_ID}-output-invoices

gsutil mb -c standard -l ${LOCATION} -b on \
    gs://${PROJECT_ID}-archived-invoices

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

gcloud pubsub topics \
    create ${GEO_CODE_REQUEST_PUBSUB_TOPIC}

cd ~/documentai-pipeline-demo/scripts

deploy_function() {
gcloud functions deploy process-invoices \
  --region=${LOCATION} \
  --entry-point=process_invoice \
  --runtime=python37 \
  --service-account=${PROJECT_ID}@appspot.gserviceaccount.com \
  --source=cloud-functions/process-invoices \
  --timeout=400 \
  --env-vars-file=cloud-functions/process-invoices/.env.yaml \
  --trigger-resource=gs://${PROJECT_ID}-input-invoices \
  --trigger-event=google.storage.object.finalize
}

deploy_success=false

while [ "$deploy_success" = false ]; do
  if deploy_function; then
    echo "Cloud Run service is created. Exiting the loop."
    deploy_success=true
  else
    echo "Waiting for Cloud Run service to be created..."
    sleep 30
  fi
done

echo "Running the next code..."

cd ~/documentai-pipeline-demo/scripts

deploy_function() {
gcloud functions deploy geocode-addresses \
  --region=${LOCATION} \
  --entry-point=process_address \
  --runtime=python38 \
  --service-account=${PROJECT_ID}@appspot.gserviceaccount.com \
  --source=cloud-functions/geocode-addresses \
  --timeout=60 \
  --env-vars-file=cloud-functions/geocode-addresses/.env.yaml \
  --trigger-topic=${GEO_CODE_REQUEST_PUBSUB_TOPIC}
}

deploy_success=false

while [ "$deploy_success" = false ]; do
  if deploy_function; then
    echo "Cloud Run service is created. Exiting the loop."
    deploy_success=true
  else
    echo "Waiting for Cloud Run service to be created..."
    sleep 30
  fi
done

echo "Running the next code..."

PROCESSOR_ID=$(curl -X GET \
  -H "Authorization: Bearer $(gcloud auth application-default print-access-token)" \
  -H "Content-Type: application/json" \
  "https://documentai.googleapis.com/v1/projects/$PROJECT_ID/locations/us/processors" | \
  grep '"name":' | \
  sed -E 's/.*"name": "projects\/[0-9]+\/locations\/us\/processors\/([^"]+)".*/\1/')

export PROCESSOR_ID

cd ~/documentai-pipeline-demo/scripts

gcloud functions deploy process-invoices \
  --region=${LOCATION} \
  --entry-point=process_invoice \
  --runtime=python37 \
  --service-account=${PROJECT_ID}@appspot.gserviceaccount.com \
  --source=cloud-functions/process-invoices \
  --timeout=400 \
  --trigger-resource=gs://${PROJECT_ID}-input-invoices \
  --trigger-event=google.storage.object.finalize \
  --update-env-vars=PROCESSOR_ID=${PROCESSOR_ID},PARSER_LOCATION=us

gcloud functions deploy geocode-addresses \
  --region=${LOCATION} \
  --entry-point=process_address \
  --runtime=python38 \
  --service-account=${PROJECT_ID}@appspot.gserviceaccount.com \
  --source=cloud-functions/geocode-addresses \
  --timeout=60 \
  --trigger-topic=${GEO_CODE_REQUEST_PUBSUB_TOPIC} \
  --update-env-vars=API_key=${API_KEY}

gsutil cp gs://sureskills-lab-dev/gsp927/documentai-pipeline-demo/sample-files/* gs://${PROJECT_ID}-input-invoices/

echo "${BG_RED}${BOLD}Congratulations For Completing The Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#