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

gcloud services disable dataflow.googleapis.com

gcloud services enable dataflow.googleapis.com

gcloud bigtable instances create ecommerce-recommendations \
  --display-name=ecommerce-recommendations \
  --cluster-storage-type=SSD \
  --cluster-config="id=ecommerce-recommendations-c1,zone=$ZONE"

gcloud bigtable clusters update ecommerce-recommendations-c1 \
    --instance=ecommerce-recommendations \
    --autoscaling-max-nodes=5 \
    --autoscaling-min-nodes=1 \
    --autoscaling-cpu-target=60 

gsutil mb gs://$DEVSHELL_PROJECT_ID

gcloud bigtable instances tables create SessionHistory \
    --instance=ecommerce-recommendations \
    --project=$DEVSHELL_PROJECT_ID \
    --column-families=Engagements,Sales

gcloud bigtable instances tables create PersonalizedProducts \
    --instance=ecommerce-recommendations \
    --project=$DEVSHELL_PROJECT_ID \
    --column-families=Recommendations

gcloud dataflow jobs run import-sessions --gcs-location gs://dataflow-templates-$REGION/latest/GCS_SequenceFile_to_Cloud_Bigtable --region $REGION --staging-location gs://$DEVSHELL_PROJECT_ID/temp --parameters bigtableProject=$DEVSHELL_PROJECT_ID,bigtableInstanceId=ecommerce-recommendations,bigtableTableId=SessionHistory,sourcePattern=gs://cloud-training/OCBL377/retail-engagements-sales-00000-of-00001,mutationThrottleLatencyMs=0

gcloud dataflow jobs run import-recommendations --gcs-location gs://dataflow-templates-$REGION/latest/GCS_SequenceFile_to_Cloud_Bigtable --region $REGION --staging-location gs://$DEVSHELL_PROJECT_ID/temp --parameters bigtableProject=$DEVSHELL_PROJECT_ID,bigtableInstanceId=ecommerce-recommendations,bigtableTableId=PersonalizedProducts,sourcePattern=gs://cloud-training/OCBL377/retail-recommendations-00000-of-00001

gcloud bigtable clusters create ecommerce-recommendations-c2 \
    --instance=ecommerce-recommendations \
    --zone=$ZONE2

gcloud bigtable clusters update ecommerce-recommendations-c2 \
    --instance=ecommerce-recommendations \
    --autoscaling-max-nodes=5 \
    --autoscaling-min-nodes=1 \
    --autoscaling-cpu-target=60 

gcloud bigtable backups create PersonalizedProducts_7 --instance=ecommerce-recommendations \
  --cluster=ecommerce-recommendations-c1 \
  --table=PersonalizedProducts \
  --retention-period=7d 

gcloud bigtable instances tables restore \
--source=projects/$DEVSHELL_PROJECT_ID/instances/ecommerce-recommendations/clusters/ecommerce-recommendations-c1/backups/PersonalizedProducts_7 \
--async \
--destination=PersonalizedProducts_7_restored \
--destination-instance=ecommerce-recommendations \
--project=$DEVSHELL_PROJECT_ID

sleep 100

gcloud dataflow jobs run import-sessions --gcs-location gs://dataflow-templates-$REGION/latest/GCS_SequenceFile_to_Cloud_Bigtable --region $REGION --staging-location gs://$DEVSHELL_PROJECT_ID/temp --parameters bigtableProject=$DEVSHELL_PROJECT_ID,bigtableInstanceId=ecommerce-recommendations,bigtableTableId=SessionHistory,sourcePattern=gs://cloud-training/OCBL377/retail-engagements-sales-00000-of-00001,mutationThrottleLatencyMs=0

gcloud dataflow jobs run import-recommendations --gcs-location gs://dataflow-templates-$REGION/latest/GCS_SequenceFile_to_Cloud_Bigtable --region $REGION --staging-location gs://$DEVSHELL_PROJECT_ID/temp --parameters bigtableProject=$DEVSHELL_PROJECT_ID,bigtableInstanceId=ecommerce-recommendations,bigtableTableId=PersonalizedProducts,sourcePattern=gs://cloud-training/OCBL377/retail-recommendations-00000-of-00001

echo "${YELLOW}${BOLD}NOW${RESET}" "${WHITE}${BOLD}Check The Score${RESET}" "${GREEN}${BOLD}Upto Task 4${RESET}"

sleep 300

gcloud bigtable backups delete PersonalizedProducts_7 --instance=ecommerce-recommendations \
  --cluster=ecommerce-recommendations-c1  --quiet

gcloud bigtable instances delete ecommerce-recommendations --quiet

echo "${BG_RED}${BOLD}Congratulations For Completing The Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#
