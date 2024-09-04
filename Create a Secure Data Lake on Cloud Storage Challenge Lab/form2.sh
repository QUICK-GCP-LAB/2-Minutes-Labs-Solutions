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
export KEY_1=domain_type
export VALUE_1=source_data

gcloud alpha dataplex lakes create customer-lake \
--display-name="Customer-Lake" \
 --location=$REGION \
 --labels="key_1=$KEY_1,value_1=$VALUE_1"

gcloud dataplex zones create public-zone \
    --lake=customer-lake \
    --location=$REGION \
    --type=RAW \
    --resource-location-type=SINGLE_REGION \
    --display-name="Public-Zone"

gcloud dataplex environments create dataplex-lake-env \
           --project=$DEVSHELL_PROJECT_ID --location=$REGION --lake=customer-lake \
           --os-image-version=1.0 --compute-node-count 3  --compute-max-node-count 3

gcloud dataplex assets create customer-raw-data --location=$REGION \
            --lake=customer-lake --zone=public-zone \
            --resource-type=STORAGE_BUCKET \
            --resource-name=projects/$DEVSHELL_PROJECT_ID/buckets/$DEVSHELL_PROJECT_ID-customer-bucket \
            --discovery-enabled \
            --display-name="Customer Raw Data"

gcloud dataplex assets create customer-reference-data --location=$REGION \
            --lake=customer-lake --zone=public-zone \
            --resource-type=BIGQUERY_DATASET \
            --resource-name=projects/$DEVSHELL_PROJECT_ID/datasets/customer_reference_data \
            --display-name="Customer Reference Data"

gcloud data-catalog tag-templates create customer_data_tag_template \
    --location=$REGION \
    --display-name="Customer Data Tag Template" \
    --field=id=data_owner,display-name="Data Owner",type=string,required=TRUE \
    --field=id=pii_data,display-name="PII Data",type='enum(Yes|No)',required=TRUE

echo "${BG_RED}${BOLD}Congratulations For Completing The Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#