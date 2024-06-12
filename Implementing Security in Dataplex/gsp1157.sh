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

gcloud services enable dataplex.googleapis.com

gcloud services enable datacatalog.googleapis.com

gcloud dataplex lakes create customer-info-lake \
  --location=$REGION \
  --display-name="Customer Info Lake"

gcloud alpha dataplex zones create customer-raw-zone \
            --location=$REGION --lake=customer-info-lake \
            --resource-location-type=SINGLE_REGION --type=RAW \
            --display-name="Customer Raw Zone"

gcloud dataplex assets create customer-online-sessions --location=$REGION \
            --lake=customer-info-lake --zone=customer-raw-zone \
            --resource-type=STORAGE_BUCKET \
            --resource-name=projects/$DEVSHELL_PROJECT_ID/buckets/$DEVSHELL_PROJECT_ID-bucket \
            --display-name="Customer Online Sessions"

echo "${CYAN}${BOLD}Click here: "${RESET}""${BLUE}${BOLD}"https://console.cloud.google.com/dataplex/secure?resourceName=projects%2F$DEVSHELL_PROJECT_ID%2Flocations%2F$REGION%2Flakes%2Fcustomer-info-lake&project=$DEVSHELL_PROJECT_ID""${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#