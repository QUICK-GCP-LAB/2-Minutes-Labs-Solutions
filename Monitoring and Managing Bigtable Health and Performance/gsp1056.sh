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

gcloud bigtable clusters update sandiego-traffic-sensors-c1 \
--instance=sandiego \
--autoscaling-min-nodes=1 \
--autoscaling-max-nodes=3 \
--autoscaling-cpu-target=60

gcloud bigtable clusters create sandiego-traffic-sensors-c2 --instance=sandiego --zone=$ZONE

gcloud bigtable clusters update sandiego-traffic-sensors-c2 \
--instance=sandiego \
--autoscaling-min-nodes=1 \
--autoscaling-max-nodes=3 \
--autoscaling-cpu-target=60

gcloud bigtable backups create current_conditions_30 --instance=sandiego \
  --cluster=sandiego-traffic-sensors-c1 \
  --table=current_conditions \
  --retention-period=30d 


gcloud bigtable instances tables restore \
--source=projects/$DEVSHELL_PROJECT_ID/instances/sandiego/clusters/sandiego-traffic-sensors-c1/backups/current_conditions_30 \
--async \
--destination=current_conditions_30_restored \
--destination-instance=sandiego \
--project=$DEVSHELL_PROJECT_ID

echo "${RED}${BOLD}Congratulations${RESET}" "${WHITE}${BOLD}for${RESET}" "${GREEN}${BOLD}Completing the Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#