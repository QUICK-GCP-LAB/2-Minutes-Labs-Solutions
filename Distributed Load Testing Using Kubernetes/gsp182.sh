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

PROJECT=$(gcloud config get-value project)
ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")
REGION=$(echo "$ZONE" | cut -d '-' -f 1-2)
CLUSTER=gke-load-test
TARGET=${PROJECT}.appspot.com
gcloud config set compute/region $REGION
gcloud config set compute/zone $ZONE

gsutil -m cp -r gs://spls/gsp182/distributed-load-testing-using-kubernetes .

cd distributed-load-testing-using-kubernetes/sample-webapp/

sed -i "s/python37/python39/g" app.yaml

cd ..

gcloud builds submit --tag gcr.io/$PROJECT/locust-tasks:latest docker-image/.

gcloud app create --region=$REGION

gcloud app deploy sample-webapp/app.yaml --quiet

gcloud container clusters create $CLUSTER \
  --zone $ZONE \
  --num-nodes=5

sed -i -e "s/\[TARGET_HOST\]/$TARGET/g" kubernetes-config/locust-master-controller.yaml
sed -i -e "s/\[TARGET_HOST\]/$TARGET/g" kubernetes-config/locust-worker-controller.yaml
sed -i -e "s/\[PROJECT_ID\]/$PROJECT/g" kubernetes-config/locust-master-controller.yaml
sed -i -e "s/\[PROJECT_ID\]/$PROJECT/g" kubernetes-config/locust-worker-controller.yaml

kubectl apply -f kubernetes-config/locust-master-controller.yaml

kubectl get pods -l app=locust-master

kubectl apply -f kubernetes-config/locust-master-service.yaml

kubectl get svc locust-master

kubectl apply -f kubernetes-config/locust-worker-controller.yaml

kubectl get pods -l app=locust-worker

kubectl scale deployment/locust-worker --replicas=20

kubectl get pods -l app=locust-worker

echo "${BG_RED}${BOLD}Congratulations For Completing The Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#