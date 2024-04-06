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

gcloud auth list

git clone https://github.com/GoogleCloudPlatform/training-data-analyst

ln -s ~/training-data-analyst/courses/developingapps/v1.2/python/kubernetesengine ~/kubernetesengine

cd ~/kubernetesengine/start

. prepare_environment.sh

gcloud container clusters create quiz-cluster --zone=$ZONE --project=$DEVSHELL_PROJECT_ID --scopes=https://www.googleapis.com/auth/cloud-platform

gcloud container clusters get-credentials quiz-cluster --zone "$ZONE" --project=$DEVSHELL_PROJECT_ID

kubectl get pods

cat > frontend/Dockerfile <<EOF_CP
FROM gcr.io/google_appengine/python

RUN virtualenv -p python3.7 /env

ENV VIRTUAL_ENV /env
ENV PATH /env/bin:$PATH

ADD requirements.txt /app/requirements.txt
RUN pip install -r /app/requirements.txt

ADD . /app

CMD gunicorn -b 0.0.0.0:$PORT quiz:app

EOF_CP

cat > backend/Dockerfile <<EOF_CP
FROM gcr.io/google_appengine/python

RUN virtualenv -p python3.7 /env

ENV VIRTUAL_ENV /env
ENV PATH /env/bin:$PATH

ADD requirements.txt /app/requirements.txt
RUN pip install -r /app/requirements.txt

ADD . /app

CMD python -m quiz.console.worker
EOF_CP

cd ~/kubernetesengine/start

gcloud builds submit -t gcr.io/$DEVSHELL_PROJECT_ID/quiz-frontend ./frontend/

gcloud builds submit -t gcr.io/$DEVSHELL_PROJECT_ID/quiz-backend ./backend/

cat > frontend-deployment.yaml <<EOF_CP
# Copyright 2017 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
apiVersion: apps/v1
kind: Deployment
metadata:
  name: quiz-frontend
  labels:
    app: quiz-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: quiz-app
      tier: frontend
  template:
    metadata:
      labels:
        app: quiz-app
        tier: frontend
    spec:
      containers:
      - name: quiz-frontend
        image: gcr.io/$GCLOUD_PROJECT/quiz-frontend
        imagePullPolicy: Always
        ports:
        - name: http-server
          containerPort: 8080
        env:
          - name: GCLOUD_PROJECT
            value: $GCLOUD_PROJECT
          - name: GCLOUD_BUCKET
            value: $GCLOUD_BUCKET

EOF_CP

cat > backend-deployment.yaml <<EOF_CP
# Copyright 2017 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
apiVersion: apps/v1
kind: Deployment
metadata:
  name: quiz-backend
  labels:
    app: quiz-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: quiz-app
      tier: backend
  template:
    metadata:
      labels:
        app: quiz-app
        tier: backend
    spec:
      containers:
      - name: quiz-backend
        image: gcr.io/$GCLOUD_PROJECT/quiz-backend
        imagePullPolicy: Always
        env:
          - name: GCLOUD_PROJECT
            value: $GCLOUD_PROJECT
          - name: GCLOUD_BUCKET
            value: $GCLOUD_BUCKET

EOF_CP

kubectl create -f ./frontend-deployment.yaml

kubectl create -f ./backend-deployment.yaml

kubectl create -f ./frontend-service.yaml

echo "${RED}${BOLD}Congratulations${RESET}" "${WHITE}${BOLD}for${RESET}" "${GREEN}${BOLD}Completing the Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#