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

echo "${YELLOW}${BOLD}Starting${RESET}" "${GREEN}${BOLD}Execution${RESET}"

export PROJECT_ID=`gcloud config get-value project`
export DATASET_ID=dataset1
export FHIR_STORE_ID=fhirstore1
export DICOM_STORE_ID=dicomstore1
export HL7_STORE_ID=hl7v2store1

gcloud services enable compute.googleapis.com container.googleapis.com dataflow.googleapis.com bigquery.googleapis.com pubsub.googleapis.com healthcare.googleapis.com

gcloud healthcare datasets create dataset1 --location=${REGION}

sleep 30

export PROJECT_ID=$(gcloud config list --format 'value(core.project)')

export PROJECT_NUMBER=$(gcloud projects list --filter=projectId:$PROJECT_ID --format="value(projectNumber)")

gcloud projects add-iam-policy-binding $PROJECT_ID --member=serviceAccount:service-$PROJECT_NUMBER@gcp-sa-healthcare.iam.gserviceaccount.com --role=roles/bigquery.admin

gcloud projects add-iam-policy-binding $PROJECT_ID \
--member=serviceAccount:service-$PROJECT_NUMBER@gcp-sa-healthcare.iam.gserviceaccount.com \
--role=roles/storage.objectAdmin

gcloud projects add-iam-policy-binding $PROJECT_ID \
--member=serviceAccount:service-$PROJECT_NUMBER@gcp-sa-healthcare.iam.gserviceaccount.com \
--role=roles/healthcare.datasetAdmin

gcloud projects add-iam-policy-binding $PROJECT_ID \
--member=serviceAccount:service-$PROJECT_NUMBER@gcp-sa-healthcare.iam.gserviceaccount.com \
--role=roles/healthcare.dicomStoreAdmin

gcloud healthcare dicom-stores create $DICOM_STORE_ID \
  --dataset=$DATASET_ID \
  --location=$REGION

curl -X POST \
     -H "Authorization: Bearer "$(sudo gcloud auth print-access-token) \
     -H "Content-Type: application/json; charset=utf-8" \
"https://healthcare.googleapis.com/v1beta1/projects/$PROJECT_ID/locations/$REGION/datasets/$DATASET_ID/dicomStores?dicomStoreId=dicomstore2"

gcloud healthcare dicom-stores import gcs $DICOM_STORE_ID \
  --dataset=$DATASET_ID \
  --location=$REGION \
  --gcs-uri=gs://gcs-public-data--healthcare-nih-chest-xray/dicom/000000*.dcm

bq mk --dataset --location=us-east4 --description DICOM $PROJECT_ID:$DATASET_ID

curl -X POST \
    -H "Authorization: Bearer "$(gcloud auth print-access-token) \
    -H "Content-Type: application/json; charset=utf-8" \
    --data "{
      'bigqueryDestination': {
        'tableUri': 'bq://$PROJECT_ID.$DATASET_ID.$DICOM_STORE_ID'
      }
    }" "https://healthcare.googleapis.com/v1beta1/projects/$PROJECT_ID/locations/$REGION/datasets/$DATASET_ID/dicomStores/$DICOM_STORE_ID:export"

#-----------------------------------------------------end----------------------------------------------------------#