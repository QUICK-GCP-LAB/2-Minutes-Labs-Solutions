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
export REPO=gmemegen
export PROJECT_ID=$(gcloud config list --format 'value(core.project)')
export CLOUDSQL_SERVICE_ACCOUNT=cloudsql-service-account

gcloud config set compute/zone $ZONE
gcloud config set compute/region $REGION

gcloud services enable artifactregistry.googleapis.com
sleep 10

gcloud iam service-accounts create $CLOUDSQL_SERVICE_ACCOUNT --project=$PROJECT_ID

gcloud projects add-iam-policy-binding $PROJECT_ID \
--member="serviceAccount:$CLOUDSQL_SERVICE_ACCOUNT@$PROJECT_ID.iam.gserviceaccount.com" \
--role="roles/cloudsql.admin"

gcloud iam service-accounts keys create $CLOUDSQL_SERVICE_ACCOUNT.json \
    --iam-account=$CLOUDSQL_SERVICE_ACCOUNT@$PROJECT_ID.iam.gserviceaccount.com \
    --project=$PROJECT_ID

gcloud container clusters create postgres-cluster \
--zone=$ZONE --num-nodes=2

kubectl create secret generic cloudsql-instance-credentials \
--from-file=credentials.json=$CLOUDSQL_SERVICE_ACCOUNT.json
    
kubectl create secret generic cloudsql-db-credentials \
--from-literal=username=postgres \
--from-literal=password=supersecret! \
--from-literal=dbname=gmemegen_db

gsutil -m cp -r gs://spls/gsp919/gmemegen .
cd gmemegen

gcloud auth configure-docker ${REGION}-docker.pkg.dev

gcloud artifacts repositories create $REPO \
    --repository-format=docker --location=$REGION

docker build -t ${REGION}-docker.pkg.dev/${PROJECT_ID}/gmemegen/gmemegen-app:v1 .

docker push ${REGION}-docker.pkg.dev/${PROJECT_ID}/gmemegen/gmemegen-app:v1

sed -i "33c\          image: $REGION-docker.pkg.dev/$PROJECT_ID/gmemegen/gmemegen-app:v1" gmemegen_deployment.yaml

sed -i "60c\                    "-instances=$PROJECT_ID:$REGION:postgres-gmemegen=tcp:5432"," gmemegen_deployment.yaml

kubectl create -f gmemegen_deployment.yaml

kubectl get pods

sleep 25

kubectl expose deployment gmemegen \
    --type "LoadBalancer" \
    --port 80 --target-port 8080

kubectl describe service gmemegen

export LOAD_BALANCER_IP=$(kubectl get svc gmemegen \
-o=jsonpath='{.status.loadBalancer.ingress[0].ip}' -n default)
echo gMemegen Load Balancer Ingress IP: http://$LOAD_BALANCER_IP

POD_NAME=$(kubectl get pods --output=json | jq -r ".items[0].metadata.name")
kubectl logs $POD_NAME gmemegen | grep "INFO"

INSTANCE_NAME="postgres-gmemegen"
DB_USER="postgres"
DB_NAME="gmemegen_db"

gcloud sql connect $INSTANCE_NAME --user=$DB_USER --quiet << EOF

\c $DB_NAME

SELECT * FROM meme;
EOF

echo "${BG_RED}${BOLD}Congratulations For Completing The Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#