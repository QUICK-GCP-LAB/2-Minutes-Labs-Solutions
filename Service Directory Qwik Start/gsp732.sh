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

gcloud services enable servicedirectory.googleapis.com

sleep 15

gcloud service-directory namespaces create example-namespace \
   --location $LOCATION

gcloud service-directory services create example-service \
   --namespace example-namespace \
   --location $LOCATION

gcloud service-directory endpoints create example-endpoint \
   --address 0.0.0.0 \
   --port 80 \
   --service example-service \
   --namespace example-namespace \
   --location $LOCATION

gcloud dns managed-zones create example-zone-name \
   --dns-name myzone.example.com \
   --description quickgcplab \
   --visibility private \
   --networks https://www.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/global/networks/default \
   --service-directory-namespace https://servicedirectory.googleapis.com/v1/projects/$DEVSHELL_PROJECT_ID/locations/$LOCATION/namespaces/example-namespace

echo "${BG_RED}${BOLD}Congratulations For Completing The Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#