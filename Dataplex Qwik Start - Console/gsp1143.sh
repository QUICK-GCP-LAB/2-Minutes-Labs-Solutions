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

gcloud services enable dataplex.googleapis.com

gcloud alpha dataplex lakes create sensors \
 --location=$REGION \
 --labels=k1=v1,k2=v2,k3=v3 

gcloud alpha dataplex zones create temperature-raw-data \
            --location=$REGION --lake=sensors \
            --resource-location-type=SINGLE_REGION --type=RAW

gsutil mb -l $REGION gs://$DEVSHELL_PROJECT_ID

gcloud dataplex assets create measurements --location=$REGION \
            --lake=sensors --zone=temperature-raw-data \
            --resource-type=STORAGE_BUCKET \
            --resource-name=projects/$DEVSHELL_PROJECT_ID/buckets/$DEVSHELL_PROJECT_ID

gcloud dataplex assets delete measurements --zone=temperature-raw-data --lake=sensors --location=$REGION --quiet

gcloud dataplex zones delete temperature-raw-data --lake=sensors --location=$REGION --quiet

gcloud dataplex lakes delete sensors --location=$REGION --quiet

echo "${RED}${BOLD}Congratulations${RESET}" "${WHITE}${BOLD}for${RESET}" "${GREEN}${BOLD}Completing the Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#