#!/bin/bash
# Define color variables for styled terminal output

BLACK=`tput setaf 0`           # Set color to black
RED=`tput setaf 1`             # Set color to red
GREEN=`tput setaf 2`           # Set color to green
YELLOW=`tput setaf 3`          # Set color to yellow
BLUE=`tput setaf 4`            # Set color to blue
MAGENTA=`tput setaf 5`         # Set color to magenta
CYAN=`tput setaf 6`            # Set color to cyan
WHITE=`tput setaf 7`           # Set color to white

BG_BLACK=`tput setab 0`        # Set background color to black
BG_RED=`tput setab 1`          # Set background color to red
BG_GREEN=`tput setab 2`        # Set background color to green
BG_YELLOW=`tput setab 3`       # Set background color to yellow
BG_BLUE=`tput setab 4`         # Set background color to blue
BG_MAGENTA=`tput setab 5`      # Set background color to magenta
BG_CYAN=`tput setab 6`         # Set background color to cyan
BG_WHITE=`tput setab 7`        # Set background color to white

BOLD=`tput bold`               # Set text style to bold
RESET=`tput sgr0`              # Reset text style and color

#----------------------------------------------------start--------------------------------------------------#

# Print message indicating the start of execution with a magenta background and bold text
echo "${BG_MAGENTA}${BOLD}Starting Execution${RESET}"

# Enable necessary Google Cloud services required for Dataplex, Data Catalog, and Dataproc
gcloud services enable \
  dataplex.googleapis.com \
  datacatalog.googleapis.com \
  dataproc.googleapis.com

# Retrieve and store project ID, default zone, and region in environment variables
export PROJECT_ID=$(gcloud config get-value project)  # Get the current project ID
export ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")  # Get the default zone for the project
export REGION=$(echo "$ZONE" | cut -d '-' -f 1-2)  # Extract region from zone (first two parts of zone)

# Create a Dataplex lake called "sales-lake" in the specified region with a description
gcloud dataplex lakes create sales-lake \
  --location=$REGION \
  --display-name="Sales Lake" \
  --description="Lake for sales data"

# Create a raw data zone within the "sales-lake" for customer data in the same region
gcloud dataplex zones create raw-customer-zone \
  --lake=sales-lake \
  --location=$REGION \
  --resource-location-type=SINGLE_REGION \
  --display-name="Raw Customer Zone" \
  --discovery-enabled \
  --discovery-schedule="0 * * * *" \  # Schedule discovery to run every hour
  --type=RAW

# Create a curated data zone within the "sales-lake" for processed customer data
gcloud dataplex zones create curated-customer-zone \
  --lake=sales-lake \
  --location=$REGION \
  --resource-location-type=SINGLE_REGION \
  --display-name="Curated Customer Zone" \
  --discovery-enabled \
  --discovery-schedule="0 * * * *" \  # Schedule discovery to run every hour
  --type=CURATED

# Create an asset within the "raw-customer-zone" for storing customer engagement data in a GCS bucket
gcloud dataplex assets create customer-engagements \
  --lake=sales-lake \
  --zone=raw-customer-zone \
  --location=$REGION \
  --display-name="Customer Engagements" \
  --resource-type=STORAGE_BUCKET \
  --resource-name=projects/$DEVSHELL_PROJECT_ID/buckets/$DEVSHELL_PROJECT_ID-customer-online-sessions \
  --discovery-enabled

# Create an asset within the "curated-customer-zone" for storing customer orders data in a BigQuery dataset
gcloud dataplex assets create customer-orders \
  --lake=sales-lake \
  --zone=curated-customer-zone \
  --location=$REGION \
  --display-name="Customer Orders" \
  --resource-type=BIGQUERY_DATASET \
  --resource-name=projects/$DEVSHELL_PROJECT_ID/datasets/customer_orders \
  --discovery-enabled

# Create a tag template in Data Catalog for marking data as protected, with two fields for raw data and protected contact info flags
gcloud data-catalog tag-templates create protected_customer_data_template \
    --location=$REGION \
    --display-name="Protected Customer Data Template" \
    --field=id=raw_data_flag,display-name="Raw Data Flag",type='enum(Yes|No)',required=TRUE \
    --field=id=protected_contact_information_flag,display-name="Protected Contact Information Flag",type='enum(Yes|No)',required=TRUE

# Add an IAM policy binding to allow user $USER_2 to write data to the "customer-engagements" asset
gcloud dataplex assets add-iam-policy-binding customer-engagements \
    --location=$REGION \
    --lake=sales-lake \
    --zone=raw-customer-zone \
    --role=roles/dataplex.dataWriter \
    --member=user:$USER_2

# Create a YAML file for defining a Data Quality rule for the "customer-orders" dataset
cat > dq-customer-orders.yaml <<EOF_CP
metadata_registry_defaults:
  dataplex:
    projects: $DEVSHELL_PROJECT_ID
    locations: $REGION
    lakes: sales-lake
    zones: curated-customer-zone
row_filters:
  NONE:
    filter_sql_expr: |-
      True
rule_dimensions:
  - completeness
rules:
  NOT_NULL:
    rule_type: NOT_NULL
    dimension: completeness
rule_bindings:
  VALID_CUSTOMER:
    entity_uri: bigquery://projects/$DEVSHELL_PROJECT_ID/datasets/customer_orders/tables/ordered_items
    column_id: user_id
    row_filter_id: NONE
    rule_ids:
      - NOT_NULL
  VALID_ORDER:
    entity_uri: bigquery://projects/$DEVSHELL_PROJECT_ID/datasets/customer_orders/tables/ordered_items
    column_id: order_id
    row_filter_id: NONE
    rule_ids:
      - NOT_NULL
EOF_CP

# Upload the Data Quality configuration YAML file to Google Cloud Storage
gsutil cp dq-customer-orders.yaml gs://$DEVSHELL_PROJECT_ID-dq-config

# Provide clickable links for accessing Dataplex in Google Cloud Console
echo "${CYAN}${BOLD}Click here: "${RESET}""${BLUE}${BOLD}"https://console.cloud.google.com/dataplex/search?project=$DEVSHELL_PROJECT_ID&qSystems=DATAPLEX""${RESET}"

# Provide clickable link to create Data Quality tasks in Dataplex
echo "${CYAN}${BOLD}Click here: "${RESET}""${BLUE}${BOLD}""https://console.cloud.google.com/dataplex/process/create-task/data-quality?project=$DEVSHELL_PROJECT_ID"""${RESET}"

# Provide instructions to follow video tutorial
echo "${YELLOW}${BOLD}NOW${RESET}" "${WHITE}${BOLD}FOLLOW${RESET}" "${GREEN}${BOLD}VIDEO'S INSTRUCTIONS${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#
