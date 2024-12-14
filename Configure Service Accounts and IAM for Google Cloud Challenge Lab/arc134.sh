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

cat > prepare_disk.sh <<'EOF_END'

gcloud auth login --quiet

export PROJECT_ID=$(gcloud config get-value project)

export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")

gcloud iam service-accounts create devops --display-name devops

sleep 45

gcloud iam service-accounts list  --filter "displayName=devops"

SA=$(gcloud iam service-accounts list --format="value(email)" --filter "displayName=devops")

gcloud projects add-iam-policy-binding $PROJECT_ID --member serviceAccount:$SA --role=roles/iam.serviceAccountUser

gcloud projects add-iam-policy-binding $PROJECT_ID --member serviceAccount:$SA --role=roles/compute.instanceAdmin

gcloud compute instances create vm-2 --machine-type e2-micro --service-account $SA --zone $ZONE --scopes "https://www.googleapis.com/auth/compute"

cat > role-definition.yaml <<EOF
title: "My Company Admin"
description: "My custom role description."
stage: "ALPHA"
includedPermissions:
- cloudsql.instances.connect
- cloudsql.instances.get
EOF

gcloud iam roles create editor --project $PROJECT_ID \
--file role-definition.yaml

gcloud iam service-accounts create bigquery-qwiklab --display-name bigquery-qwiklab

SA=$(gcloud iam service-accounts list --format="value(email)" --filter "displayName=bigquery-qwiklab")

gcloud projects add-iam-policy-binding $PROJECT_ID --member=serviceAccount:$SA --role=roles/bigquery.dataViewer

gcloud projects add-iam-policy-binding $PROJECT_ID --member=serviceAccount:$SA --role=roles/bigquery.user

gcloud compute instances create bigquery-instance --service-account=$SA --scopes=https://www.googleapis.com/auth/bigquery --zone=$ZONE
EOF_END

gcloud compute scp prepare_disk.sh lab-vm:/tmp --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet

gcloud compute ssh lab-vm --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet --command="bash /tmp/prepare_disk.sh"

sleep 30

cat > prepare_disk.sh <<'EOF_END'
sudo apt-get update
sudo apt install python3 -y
sudo apt-get install -y git python3-pip
sudo apt install python3.11-venv -y
python3 -m venv create myvenv
source myvenv/bin/activate
pip3 install --upgrade pip
pip3 install google-cloud-bigquery
pip3 install pyarrow
pip3 install pandas
pip3 install db-dtypes
pip3 install --upgrade google-cloud

export PROJECT_ID=$(gcloud config get-value project)
export SA_EMAIL=$(curl -s "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/email" -H "Metadata-Flavor: Google")

echo "
from google.auth import compute_engine
from google.cloud import bigquery
credentials = compute_engine.Credentials(
service_account_email='$SA_EMAIL')
query = '''
SELECT name, SUM(number) as total_people
FROM "bigquery-public-data.usa_names.usa_1910_2013"
WHERE state = 'TX'
GROUP BY name, state
ORDER BY total_people DESC
LIMIT 20
'''
client = bigquery.Client(
  project='$PROJECT_ID',
  credentials=credentials)
print(client.query(query).to_dataframe())
" > query.py

sleep 10

python3 query.py
EOF_END

gcloud compute scp prepare_disk.sh bigquery-instance:/tmp --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet

gcloud compute ssh bigquery-instance --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet --command="bash /tmp/prepare_disk.sh"

echo "${BG_RED}${BOLD}Congratulations For Completing The Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#
