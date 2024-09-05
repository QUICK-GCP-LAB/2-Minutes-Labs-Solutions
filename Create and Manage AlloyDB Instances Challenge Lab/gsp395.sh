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

export ZONE=$(gcloud compute instances list alloydb-client --format 'csv[no-heading](zone)')

export REGION="${ZONE%-*}"

gcloud beta alloydb clusters create lab-cluster \
    --password=Change3Me \
    --network=peering-network \
    --region=$REGION \
    --project=$DEVSHELL_PROJECT_ID

gcloud beta alloydb instances create lab-instance \
    --instance-type=PRIMARY \
    --cpu-count=2 \
    --region=$REGION  \
    --cluster=lab-cluster \
    --project=$DEVSHELL_PROJECT_ID

gcloud alloydb instances create lab-instance-rp1 \
  --cluster=lab-cluster \
  --region=$REGION \
  --instance-type=READ_POOL \
  --cpu-count=2 \
  --read-pool-node-count=2

gcloud beta alloydb backups create lab-backup --region=$REGION  --cluster=lab-cluster

gcloud compute ssh alloydb-client --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet