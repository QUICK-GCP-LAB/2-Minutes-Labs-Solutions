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

export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')
gcloud config set compute/region $REGION

gcloud services enable \
cloudresourcemanager.googleapis.com \
container.googleapis.com \
sourcerepo.googleapis.com \
cloudbuild.googleapis.com \
containerregistry.googleapis.com \
run.googleapis.com

sleep 30

gcloud projects add-iam-policy-binding $PROJECT_ID \
--member=serviceAccount:$PROJECT_NUMBER@cloudbuild.gserviceaccount.com \
--role=roles/run.admin

gcloud iam service-accounts add-iam-policy-binding \
$PROJECT_NUMBER-compute@developer.gserviceaccount.com \
--member=serviceAccount:$PROJECT_NUMBER@cloudbuild.gserviceaccount.com \
--role=roles/iam.serviceAccountUser

git config --global user.email "quickgcplab@gmail.com"
git config --global user.name "quickgcplab"


git clone https://github.com/GoogleCloudPlatform/software-delivery-workshop --branch cloudrun-progression-csr cloudrun-progression
cd cloudrun-progression/labs/cloudrun-progression
rm -rf ../../.git

sed "s/PROJECT/${PROJECT_ID}/g" branch-trigger.json-tmpl > branch-trigger.json
sed "s/PROJECT/${PROJECT_ID}/g" master-trigger.json-tmpl > master-trigger.json
sed "s/PROJECT/${PROJECT_ID}/g" tag-trigger.json-tmpl > tag-trigger.json

gcloud source repos create cloudrun-progression
git init
git config credential.helper gcloud.sh
git remote add gcp https://source.developers.google.com/p/$PROJECT_ID/r/cloudrun-progression
git branch -m master
git add . && git commit -m "initial commit"
git push gcp master

sleep 30

gcloud builds submit --tag gcr.io/$PROJECT_ID/hello-cloudrun
gcloud run deploy hello-cloudrun \
--image gcr.io/$PROJECT_ID/hello-cloudrun \
--platform managed \
--region $REGION \
--tag=prod -q


PROD_URL=$(gcloud run services describe hello-cloudrun --platform managed --region $REGION --format=json | jq --raw-output ".status.url")
echo $PROD_URL
curl -H "Authorization: Bearer $(gcloud auth print-identity-token)" $PROD_URL

sleep 30

gcloud beta builds triggers create cloud-source-repositories --trigger-config branch-trigger.json

git checkout -b new-feature-1

cat > app.py <<EOF
#!/usr/bin/python
#
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
import os

from flask import Flask

app = Flask(__name__)

@app.route('/')
def hello_world():
    return 'Hello World v1.1'

if __name__ == "__main__":
    app.run(debug=True,host='0.0.0.0',port=int(os.environ.get('PORT', 8080)))

EOF

git add . && git commit -m "updated" && git push gcp new-feature-1

BRANCH_URL=$(gcloud run services describe hello-cloudrun --platform managed --region $REGION --format=json | jq --raw-output ".status.traffic[] | select (.tag==\"new-feature-1\")|.url")
echo $BRANCH_URL

curl -H "Authorization: Bearer $(gcloud auth print-identity-token)" $BRANCH_URL

sleep 30

gcloud beta builds triggers create cloud-source-repositories --trigger-config master-trigger.json

git checkout master
git merge new-feature-1
git push gcp master

sleep 30

gcloud beta builds triggers create cloud-source-repositories --trigger-config tag-trigger.json

git tag 1.1
git push gcp 1.1

echo "${BG_RED}${BOLD}Congratulations For Completing The Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#