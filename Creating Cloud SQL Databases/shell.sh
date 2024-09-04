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



gcloud services enable sqladmin.googleapis.com --project=$DEVSHELL_PROJECT_ID

gcloud sql instances create postgresql-db --zone=$ZONE --database-version=POSTGRES_14 --tier=db-custom-1-3840 --root-password=awesome --edition=ENTERPRISE

gcloud sql databases create petsdb --instance=postgresql-db

gcloud sql instances create mysql-db --tier=db-n1-standard-1 --zone=$ZONE

gcloud compute instances create test-client  --zone=$ZONE --image-family=debian-11 --image-project=debian-cloud --machine-type=e2-micro

INSTANCE_NAME="mysql-db"
EXTERNAL=$(gcloud compute instances list --format='value(EXTERNAL_IP)')

gcloud sql instances patch $INSTANCE_NAME --authorized-networks=$EXTERNAL --quiet

INSTANCE_NAME="mysql-db"
PUBLIC_IP=$(gcloud sql instances describe $INSTANCE_NAME --format="value(ipAddresses.ipAddress)")

gcloud sql instances patch $INSTANCE_NAME --authorized-networks=$EXTERNAL --quiet

gcloud compute ssh test-client --zone=$ZONE --quiet --command "sudo apt-get update && sudo apt-get install -y default-mysql-client && mysql --host=$PUBLIC_IP --user=root --password"

echo "${BG_RED}${BOLD}Congratulations For Completing The Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#