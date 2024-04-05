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

export ID=$DEVSHELL_PROJECT_ID

gcloud services enable datacatalog.googleapis.com
gcloud services enable dataplex.googleapis.com

gcloud dataplex lakes create customer-engagements \
   --location=$LOCATION \
   --display-name="Customer Engagements"

gcloud dataplex zones create raw-event-data \
    --location=$LOCATION \
    --lake=customer-engagements \
    --display-name="Raw Event Data" \
    --type=RAW \
    --resource-location-type=SINGLE_REGION \
    --discovery-enabled

gsutil mb -p $ID -c REGIONAL -l $LOCATION gs://$ID

gcloud dataplex assets create raw-event-files \
--location=$LOCATION \
--lake=customer-engagements \
--zone=raw-event-data \
--display-name="Raw Event Files" \
--resource-type=STORAGE_BUCKET \
--resource-name=projects/my-project/buckets/${ID}

echo "${RED}${BOLD}Congratulations${RESET}" "${WHITE}${BOLD}for${RESET}" "${GREEN}${BOLD}Completing the Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#