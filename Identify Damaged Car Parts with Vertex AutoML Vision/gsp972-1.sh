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

export PROJECT_ID=$DEVSHELL_PROJECT_ID
export BUCKET=$PROJECT_ID

gsutil mb -p $PROJECT_ID \
    -c standard    \
    -l $REGION \
    gs://${BUCKET}

gsutil -m cp -r gs://car_damage_lab_images/* gs://${BUCKET}

gsutil cp gs://car_damage_lab_metadata/data.csv .

sed -i -e "s/car_damage_lab_images/${BUCKET}/g" ./data.csv

cat ./data.csv

gsutil cp ./data.csv gs://${BUCKET}

echo "${YELLOW}${BOLD}NOW${RESET}" "${WHITE}${BOLD}FOLLOW${RESET}" "${GREEN}${BOLD}VIDEO'S INSTRUCTIONS${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#