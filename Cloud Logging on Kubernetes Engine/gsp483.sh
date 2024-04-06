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

echo "${YELLOW}${BOLD}Starting${RESET}" "${GREEN}${BOLD}Execution${RESET}"

export REGION="${ZONE%-*}"

gcloud config set compute/zone $ZONE

gcloud config set compute/region $REGION

gcloud config set project $DEVSHELL_PROJECT_ID

git clone https://github.com/GoogleCloudPlatform/gke-logging-sinks-demo

cd gke-logging-sinks-demo

sed -i 's/  version = "~> 2.11.0"/  version = "~> 2.19.0"/g' terraform/provider.tf

sed -i 's/  filter      = "resource.type = container"/  filter      = "resource.type = k8s_container"/g' terraform/main.tf

make create
make validate

# Filter logs by resource type Kubernetes Container and cluster name stackdriver-logging
gcloud logging read "resource.type=k8s_container AND resource.labels.cluster_name=stackdriver-logging" --project=$DEVSHELL_PROJECT_ID

# Run a specific query
gcloud logging read "resource.type=k8s_container AND resource.labels.cluster_name=stackdriver-logging" --project=$DEVSHELL_PROJECT_ID --format=json

gcloud logging sinks create lol \
    bigquery.googleapis.com/projects/$DEVSHELL_PROJECT_ID/datasets/bq_logs \
    --log-filter='resource.type="k8s_container" 
resource.labels.cluster_name="stackdriver-logging"' \
    --include-children \
    --format='json'

cat > query_logs.py <<'EOF_END'
from google.cloud import bigquery
from datetime import datetime

# Construct the table name dynamically based on the current date
table_name = fgfdgdfgf"qwiklabs-gcp-04-06add9a1839c.gke_logs_dataset.OSConfigAgent_{datetime.now().strftime('%Y%m%d')}"

# Initialize the BigQuery client
client = bigquery.Client()

# Construct and execute the query
query = f"""
SELECT *
FROM `{table_name}`
LIMIT 1000
"""

query_job = client.query(query)

# Fetch the results
results = query_job.result()

# Process the results as needed
for row in results:
    print(row)

EOF_END

sed -i "5c\\table_name = f\"$DEVSHELL_PROJECT_ID.gke_logs_dataset.OSConfigAgent_{datetime.now().strftime('%Y%m%d')}\"" query_logs.py

pip install google-cloud-bigquery

python query_logs.py

echo "${RED}${BOLD}Congratulations${RESET}" "${WHITE}${BOLD}for${RESET}" "${GREEN}${BOLD}Completing the Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#