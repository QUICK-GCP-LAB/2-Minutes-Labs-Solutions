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

export VM_EXT_IP=$(gcloud compute instances describe cls-vm --zone=$ZONE \
  --format='get(networkInterfaces[0].accessConfigs[0].natIP)')

gsutil mb -p $DEVSHELL_PROJECT_ID -c STANDARD -l $REGION -b on gs://scc-export-bucket-$DEVSHELL_PROJECT_ID

gsutil uniformbucketlevelaccess set off gs://scc-export-bucket-$DEVSHELL_PROJECT_ID

curl -LO raw.githubusercontent.com/QUICK-GCP-LAB/2-Minutes-Labs-Solutions/refs/heads/main/Mitigate%20Threats%20and%20Vulnerabilities%20with%20Security%20Command%20Center%20Challenge%20Lab/findings.jsonl

gsutil cp findings.jsonl gs://scc-export-bucket-$DEVSHELL_PROJECT_ID

echo "${CYAN}${BOLD}Click here: "${RESET}""${BLUE}${BOLD}""https://console.cloud.google.com/security/web-scanner/scanConfigs/edit?project=$DEVSHELL_PROJECT_ID"""${RESET}"

echo "${YELLOW}${BOLD}Copy this: "${RESET}""${GREEN}${BOLD}""http://$VM_EXT_IP:8080"""${RESET}"

echo "${YELLOW}${BOLD}NOW${RESET}" "${WHITE}${BOLD}FOLLOW${RESET}" "${GREEN}${BOLD}VIDEO'S INSTRUCTIONS${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#