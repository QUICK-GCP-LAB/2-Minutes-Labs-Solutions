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

gcloud services enable pubsub.googleapis.com
gcloud services enable run.googleapis.com

gcloud config set compute/region $LOCATION

 gcloud run deploy store-service \
  --image gcr.io/qwiklabs-resources/gsp724-store-service \
  --region $LOCATION \
  --allow-unauthenticated

 gcloud run deploy order-service \
  --image gcr.io/qwiklabs-resources/gsp724-order-service \
  --region $LOCATION \
  --no-allow-unauthenticated

gcloud pubsub topics create ORDER_PLACED

 gcloud iam service-accounts create pubsub-cloud-run-invoker \
  --display-name "Order Initiator"

export ORDER_SERVICE_URL=$(gcloud run services describe order-service \
   --region $LOCATION \
   --format="value(status.address.url)")

gcloud pubsub subscriptions create order-service-sub \
   --topic ORDER_PLACED \
   --push-endpoint=$ORDER_SERVICE_URL \
   --push-auth-service-account=pubsub-cloud-run-invoker@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com

echo "${BG_RED}${BOLD}Congratulations For Completing The Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#