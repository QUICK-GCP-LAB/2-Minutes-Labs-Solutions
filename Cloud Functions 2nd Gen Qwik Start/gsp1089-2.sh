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

cd min-instances/

SLOW_URL=$(gcloud functions describe slow-function --region $REGION --gen2 --format="value(serviceConfig.uri)")

hey -n 10 -c 10 $SLOW_URL

gcloud run services delete slow-function --region $REGION --quiet

gcloud functions deploy slow-concurrent-function \
  --gen2 \
  --runtime go116 \
  --entry-point HelloWorld \
  --source . \
  --region $REGION \
  --trigger-http \
  --allow-unauthenticated \
  --min-instances 1 \
  --max-instances 4 \
  --quiet

# Transform DEVSHELL_PROJECT_ID and REGION
export spcl_project=$(echo "$DEVSHELL_PROJECT_ID" | sed 's/-/--/g; s/$/__/g')
export my_region=$(echo "$REGION" | sed 's/-/--/g; s/$/__/g')

# Build the final string
export full_path="$REGION-docker.pkg.dev/$DEVSHELL_PROJECT_ID/gcf-artifacts/$spcl_project$my_region"

# Append the static part
export full_path="${full_string}slow--concurrent--function:version_1"

gcloud run deploy slow-concurrent-function \
--image=$full_path \
--concurrency=100 \
--cpu=1 \
--max-instances=4 \
--region=$REGION \
--project=$DEVSHELL_PROJECT_ID \
 && gcloud run services update-traffic slow-concurrent-function --to-latest --region=$REGION

echo "${CYAN}${BOLD}Click here: "${RESET}""${BLUE}${BOLD}"https://console.cloud.google.com/run/deploy/$REGION/slow-concurrent-function?project=$DEVSHELL_PROJECT_ID""${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#