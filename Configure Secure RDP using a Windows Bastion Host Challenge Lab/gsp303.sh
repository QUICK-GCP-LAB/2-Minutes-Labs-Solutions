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

export REGION=${ZONE%-*}

gcloud compute networks create securenetwork --subnet-mode custom

gcloud compute networks subnets create securenetwork-subnet --network=securenetwork --region $REGION --range=192.168.16.0/20

gcloud compute firewall-rules create rdp-ingress-fw-rule --allow=tcp:3389 --source-ranges 0.0.0.0/0 --target-tags allow-rdp-traffic --network securenetwork

gcloud compute instances create vm-bastionhost --zone=$ZONE --machine-type=e2-medium --network-interface=subnet=securenetwork-subnet --network-interface=subnet=default,no-address --tags=allow-rdp-traffic --image=projects/windows-cloud/global/images/windows-server-2016-dc-v20220513

gcloud compute instances create vm-securehost --zone=$ZONE --machine-type=e2-medium --network-interface=subnet=securenetwork-subnet,no-address --network-interface=subnet=default,no-address --tags=allow-rdp-traffic --image=projects/windows-cloud/global/images/windows-server-2016-dc-v20220513

sleep 300

echo "${CYAN}${BOLD}Resetting ${RESET}""${RED}${BOLD}password${RESET}" "${WHITE}${BOLD}for${RESET}" "${GREEN}${BOLD}vm-bastionhost${RESET}"

gcloud compute reset-windows-password vm-bastionhost --user app_admin --zone $ZONE --quiet

echo "${CYAN}${BOLD}Resetting ${RESET}""${RED}${BOLD}password${RESET}" "${WHITE}${BOLD}for${RESET}" "${BLUE}${BOLD}vm-securehost${RESET}"

gcloud compute reset-windows-password vm-securehost --user app_admin --zone $ZONE --quiet

echo "${BG_RED}${BOLD}Congratulations For Completing The Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#
