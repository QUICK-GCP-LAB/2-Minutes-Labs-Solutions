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

gcloud storage cp -r gs://spls/gsp023/flex_and_vision/ .

cd flex_and_vision

export PROJECT_ID=$(gcloud config get-value project)

gcloud iam service-accounts create qwiklab \
  --display-name "My qwiklab Service Account"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
--member serviceAccount:qwiklab@${PROJECT_ID}.iam.gserviceaccount.com \
--role roles/owner

gcloud iam service-accounts keys create ~/key.json \
--iam-account qwiklab@${PROJECT_ID}.iam.gserviceaccount.com

export GOOGLE_APPLICATION_CREDENTIALS="/home/${USER}/key.json"

virtualenv -p python3 env

source env/bin/activate

pip install -r requirements.txt

gcloud app create --region=us-east1 

export CLOUD_STORAGE_BUCKET=${PROJECT_ID}

gsutil mb gs://${PROJECT_ID}

cat> app.yaml <<EOF
# Copyright 2021 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

runtime: python
env: flex
entrypoint: gunicorn -b :8080 main:app

runtime_config:
  python_version: 3.7

env_variables:
  CLOUD_STORAGE_BUCKET: $PROJECT_ID
manual_scaling:
  instances: 1
EOF

gcloud config set app/cloud_build_timeout 1000

gcloud app deploy --quiet &  
sleep 30 
timeout 1 gcloud app versions list 
python main.py  