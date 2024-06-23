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

gcloud config set compute/zone $ZONE

gcloud services enable cloudbuild.googleapis.com

gcloud services enable container.googleapis.com

git clone https://github.com/googlecodelabs/monolith-to-microservices.git

cd ~/monolith-to-microservices
./setup.sh

cd ~/monolith-to-microservices/monolith
gcloud builds submit --tag gcr.io/${GOOGLE_CLOUD_PROJECT}/${MON_IDENT}:1.0.0 .

gcloud container clusters create $CLUSTER --num-nodes 3

kubectl create deployment $MON_IDENT --image=gcr.io/${GOOGLE_CLOUD_PROJECT}/$MON_IDENT:1.0.0

kubectl expose deployment $MON_IDENT --type=LoadBalancer --port 80 --target-port 8080

cd ~/monolith-to-microservices/microservices/src/orders
gcloud builds submit --tag gcr.io/${GOOGLE_CLOUD_PROJECT}/$ORD_IDENT:1.0.0 .

cd ~/monolith-to-microservices/microservices/src/products
gcloud builds submit --tag gcr.io/${GOOGLE_CLOUD_PROJECT}/$PROD_IDENT:1.0.0 .

kubectl create deployment $ORD_IDENT --image=gcr.io/${GOOGLE_CLOUD_PROJECT}/$ORD_IDENT:1.0.0

kubectl expose deployment $ORD_IDENT --type=LoadBalancer --port 80 --target-port 8081

kubectl create deployment $PROD_IDENT --image=gcr.io/${GOOGLE_CLOUD_PROJECT}/$PROD_IDENT:1.0.0
kubectl expose deployment $PROD_IDENT --type=LoadBalancer --port 80 --target-port 8082

cd ~/monolith-to-microservices/react-app
cd ~/monolith-to-microservices/microservices/src/frontend

gcloud builds submit --tag gcr.io/${GOOGLE_CLOUD_PROJECT}/$FRONT_IDENT:1.0.0 .

kubectl create deployment $FRONT_IDENT --image=gcr.io/${GOOGLE_CLOUD_PROJECT}/$FRONT_IDENT:1.0.0
kubectl expose deployment $FRONT_IDENT --type=LoadBalancer --port 80 --target-port 8080

echo "${BG_RED}${BOLD}Congratulations For Completing The Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#