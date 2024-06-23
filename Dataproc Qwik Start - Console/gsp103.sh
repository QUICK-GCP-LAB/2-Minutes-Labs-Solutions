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

export REGION="${ZONE%-*}"

export PROJECT_NUMBER="$(gcloud projects describe $DEVSHELL_PROJECT_ID --format='get(projectNumber)')"

gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
    --member serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com \
    --role roles/storage.objectAdmin

gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
    --member serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com \
    --role roles/dataproc.worker

gcloud compute networks subnets update default \
    --region $REGION \
    --enable-private-ip-google-access

gcloud dataproc clusters create example-cluster --region $REGION --zone $ZONE --master-machine-type e2-standard-2 --master-boot-disk-type pd-balanced --master-boot-disk-size 30 --num-workers 2 --worker-machine-type e2-standard-2 --worker-boot-disk-type pd-balanced --worker-boot-disk-size 30 --image-version 2.2-debian12 --project $DEVSHELL_PROJECT_ID

gcloud dataproc jobs submit spark \
    --cluster example-cluster \
    --region $REGION \
    --class org.apache.spark.examples.SparkPi \
    --jars file:///usr/lib/spark/examples/jars/spark-examples.jar \
    -- 1000

gcloud dataproc clusters update example-cluster \
    --region $REGION \
    --num-workers 4

echo "${BG_RED}${BOLD}Congratulations For Completing The Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#