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

export PROJECT_ID=$(gcloud info --format="value(config.project)")

git clone https://github.com/GoogleCloudPlatform/DIY-Tools.git

gcloud firestore import gs://$PROJECT_ID-firestore/prd-back

PROJECT_NUMBER=$(gcloud projects list --filter="PROJECT_ID=$PROJECT_ID" --format="value(PROJECT_NUMBER)")
SERVICE_ACCOUNT_EMAIL="${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member "serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
    --role "roles/artifactregistry.reader"

cd ~/DIY-Tools/gcp-data-drive

gcloud builds submit --config cloudbuild_run.yaml \
  --project $PROJECT_ID --no-source \
  --substitutions=_GIT_SOURCE_BRANCH="master",_GIT_SOURCE_URL="https://github.com/GoogleCloudPlatform/DIY-Tools"

gcloud beta run services add-iam-policy-binding --region=$REGION --member=allUsers --role=roles/run.invoker gcp-data-drive

export CLOUD_RUN_SERVICE_URL=$(gcloud run services --platform managed describe gcp-data-drive --region $REGION --format="value(status.url)")

curl $CLOUD_RUN_SERVICE_URL/fs/$PROJECT_ID/symbols/product/symbol | jq .

curl $CLOUD_RUN_SERVICE_URL/bq/$PROJECT_ID/publicviews/ca_zip_codes | jq .

sleep 60

#TASK 3

cat > cloudbuild_gcf.yaml <<'EOF_END'
# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#       https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

steps:
- name: 'gcr.io/cloud-builders/git'
# The gcloud command used to call this cloud build uses the --no-source switch which ensures the source builds correctly. As a result we need to
# clone the specified source to preform the build.
  args: ['clone','--single-branch','--branch','${_GIT_SOURCE_BRANCH}','${_GIT_SOURCE_URL}']

- name: 'gcr.io/cloud-builders/gcloud'
  args: ['functions','deploy','gcp-data-drive','--trigger-http','--runtime','go121','--entry-point','GetJSONData', '--project','$PROJECT_ID','--memory','2048']
  dir: 'DIY-Tools/gcp-data-drive'
EOF_END

gcloud builds submit --config cloudbuild_gcf.yaml --project $PROJECT_ID --no-source --substitutions=_GIT_SOURCE_BRANCH="master",_GIT_SOURCE_URL="https://github.com/GoogleCloudPlatform/DIY-Tools"

gcloud alpha functions add-iam-policy-binding gcp-data-drive --member=allUsers --role=roles/cloudfunctions.invoker

export CF_TRIGGER_URL=$(gcloud functions describe gcp-data-drive --format="value(httpsTrigger.url)")

curl $CF_TRIGGER_URL/fs/$PROJECT_ID/symbols/product/symbol | jq .

curl $CF_TRIGGER_URL/bq/$PROJECT_ID/publicviews/ca_zip_codes

#TASK 4

# sed -i "s/go121/go113/g" cmd/webserver/app.yaml

# sed -i "s/go113/go121/g" cmd/webserver/app.yaml

cat > cloudbuild_appengine.yaml <<'EOF_END'
# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#       https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

steps:
- name: 'gcr.io/cloud-builders/git'
# The gcloud command used to call this cloud build uses the --no-source switch which ensures the source build correctly. As a result we need to
# clone the specified source to preform the build.
  args: ['clone','--single-branch','--branch','${_GIT_SOURCE_BRANCH}','${_GIT_SOURCE_URL}']

- name: 'ubuntu'  # Or any base image containing 'sed'
  args: ['sed', '-i', 's/runtime: go113/runtime: go121/', 'app.yaml'] # Replace go113 with go121
  dir: 'DIY-Tools/gcp-data-drive/cmd/webserver'

- name: 'gcr.io/cloud-builders/gcloud'
  args: ['app','deploy','app.yaml','--project','$PROJECT_ID']
  dir: 'DIY-Tools/gcp-data-drive/cmd/webserver'
EOF_END

gcloud builds submit  --config cloudbuild_appengine.yaml \
   --project $PROJECT_ID --no-source \
   --substitutions=_GIT_SOURCE_BRANCH="master",_GIT_SOURCE_URL="https://github.com/GoogleCloudPlatform/DIY-Tools"

export TARGET_URL=https://$(gcloud app describe --format="value(defaultHostname)")

curl $TARGET_URL/fs/$PROJECT_ID/symbols/product/symbol | jq .

curl $TARGET_URL/bq/$PROJECT_ID/publicviews/ca_zip_codes | jq .

cat > loadgen.sh <<EOF
#!/bin/bash
for ((i=1;i<=1000;i++));
do
   curl $TARGET_URL/bq/$PROJECT_ID/publicviews/ca_zip_codes > /dev/null &
done
EOF

gcloud builds submit --config cloudbuild_gcf.yaml --project $PROJECT_ID --no-source --substitutions=_GIT_SOURCE_BRANCH="master",_GIT_SOURCE_URL="https://github.com/GoogleCloudPlatform/DIY-Tools"

chmod +x loadgen.sh

./loadgen.sh

echo "${BG_RED}${BOLD}Congratulations For Completing The Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#