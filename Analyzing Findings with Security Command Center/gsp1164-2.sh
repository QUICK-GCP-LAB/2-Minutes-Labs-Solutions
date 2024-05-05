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

export REGION="${ZONE%-*}"
gcloud pubsub subscriptions update export-findings-pubsub-topic-sub --ack-deadline 10
gcloud compute instances create instance-1 --zone=$ZONE \
--machine-type e2-micro \
--scopes=https://www.googleapis.com/auth/cloud-platform
gcloud alpha pubsub subscriptions pull export-findings-pubsub-topic-sub --max-messages=10
PROJECT_ID=$(gcloud config get project)
bq --location=$REGION --apilog=/dev/null mk --dataset \
$PROJECT_ID:continuous_export_dataset
gcloud services enable securitycenter.googleapis.com
gcloud scc bqexports create scc-bq-cont-export --dataset=projects/$DEVSHELL_PROJECT_ID/datasets/continuous_export_dataset --project=$DEVSHELL_PROJECT_ID
for i in {0..2}; do
gcloud iam service-accounts create sccp-test-sa-$i;
gcloud iam service-accounts keys create /tmp/sa-key-$i.json \
--iam-account=sccp-test-sa-$i@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com;
done
bq query --apilog=/dev/null --use_legacy_sql=false  \
"SELECT finding_id,event_time,finding.category FROM continuous_export_dataset.findings"
export BUCKET_NAME=scc-export-bucket-$DEVSHELL_PROJECT_ID

gcloud storage buckets create gs://$BUCKET_NAME --location=$REGION