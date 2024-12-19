clear

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

# Array of color codes excluding black and white
TEXT_COLORS=($RED $GREEN $YELLOW $BLUE $MAGENTA $CYAN)
BG_COLORS=($BG_RED $BG_GREEN $BG_YELLOW $BG_BLUE $BG_MAGENTA $BG_CYAN)

# Pick random colors
RANDOM_TEXT_COLOR=${TEXT_COLORS[$RANDOM % ${#TEXT_COLORS[@]}]}
RANDOM_BG_COLOR=${BG_COLORS[$RANDOM % ${#BG_COLORS[@]}]}

#----------------------------------------------------start--------------------------------------------------#

echo "${RANDOM_BG_COLOR}${RANDOM_TEXT_COLOR}${BOLD}Starting Execution${RESET}"

export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")

export PROJECT_ID=$(gcloud config get-value project)

export PROJECT_NUMBER=$(gcloud projects describe ${PROJECT_ID} \
    --format="value(projectNumber)")

curl -LO 

cd stackdriver-lab

sed -i "s/us-west1-b/$ZONE/g" setup.sh

./setup.sh

bq mk project_logs

gcloud logging sinks create vm_logs \
    bigquery.googleapis.com/projects/$DEVSHELL_PROJECT_ID/datasets/project_logs \
    --log-filter='resource.type="gce_instance"'

gcloud logging sinks create load_bal_logs \
    bigquery.googleapis.com/projects/$DEVSHELL_PROJECT_ID/datasets/project_logs \
    --log-filter="resource.type=\"http_load_balancer\""

gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
  --member=serviceAccount:service-$PROJECT_NUMBER@gcp-sa-logging.iam.gserviceaccount.com \
  --role=roles/bigquery.dataEditor

TABLE_ID=$(bq ls --project_id $DEVSHELL_PROJECT_ID --dataset_id project_logs --format=json | jq -r '.[0].tableReference.tableId')

bq query --use_legacy_sql=false \
"
SELECT
  logName, resource.type, resource.labels.zone, resource.labels.project_id,
FROM
  \`$DEVSHELL_PROJECT_ID.project_logs.$TABLE_ID\`
"

gcloud logging metrics create 403s \
    --description="Counts syslog entries with resource.type=gce_instance" \
    --log-filter="resource.type=\"gce_instance\" AND logName=\"projects/$DEVSHELL_PROJECT_ID/logs/syslog\""