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

gcloud services enable apikeys.googleapis.com

gsutil cp gs://spls/gsp164/endpoints-quickstart.zip .
unzip endpoints-quickstart.zip

cd endpoints-quickstart

cd scripts

./deploy_api.sh

./deploy_app.sh ../app/app_template.yaml $REGION

./query_api.sh

./query_api.sh JFK

./deploy_api.sh ../openapi_with_ratelimit.yaml

./deploy_app.sh ../app/app_template.yaml $REGION

gcloud alpha services api-keys create --display-name="awesome" 

KEY_NAME=$(gcloud alpha services api-keys list --format="value(name)" --filter "displayName=awesome")

export API_KEY=$(gcloud alpha services api-keys get-key-string $KEY_NAME --format="value(keyString)")

./query_api_with_key.sh $API_KEY

./generate_traffic_with_key.sh $API_KEY

./query_api_with_key.sh $API_KEY

echo "${BG_RED}${BOLD}Congratulations For Completing The Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#