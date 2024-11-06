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

POSTGRES_INSTANCE=postgres-db
export PUBLIC_IP=$(gcloud sql instances describe $POSTGRES_INSTANCE --format="value(ipAddresses[0].ipAddress)")
export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")
export REGION=$(echo "$ZONE" | cut -d '-' -f 1-2)
echo "${CYAN}${BOLD}Click here: "${RESET}""${BLUE}${BOLD}""https://console.cloud.google.com/datastream/connection-profiles/create/POSTGRESQL?project=$DEVSHELL_PROJECT_ID"""${RESET}"
echo "${YELLOW}${BOLD}your REGION is${RESET}" "${GREEN}${BOLD}"$REGION"${RESET}"
echo "${RED}${BOLD}Copy this: "${RESET}""${WHITE}${BOLD}"$PUBLIC_IP""${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#
