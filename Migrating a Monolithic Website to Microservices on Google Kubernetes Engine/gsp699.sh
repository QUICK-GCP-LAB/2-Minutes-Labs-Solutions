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
export REGION=${ZONE%-*}
gcloud config set compute/region $REGION

export PROJECT_ID=$DEVSHELL_PROJECT_ID

cd ~
git clone https://github.com/googlecodelabs/monolith-to-microservices.git
cd ~/monolith-to-microservices
./setup.sh

gcloud services enable container.googleapis.com --project=$DEVSHELL_PROJECT_ID

gcloud container clusters create fancy-cluster --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --num-nodes 3 --machine-type=e2-standard-4

gcloud compute instances list

cd ~/monolith-to-microservices
./deploy-monolith.sh

kubectl get service monolith

sleep 30

echo "http://$(kubectl get service monolith -o=jsonpath='{.status.loadBalancer.ingress[0].ip}')"

cd ~/monolith-to-microservices/microservices/src/orders
gcloud builds submit --tag gcr.io/${GOOGLE_CLOUD_PROJECT}/orders:1.0.0 .

kubectl create deployment orders --image=gcr.io/${GOOGLE_CLOUD_PROJECT}/orders:1.0.0

kubectl get all

sleep 30

kubectl expose deployment orders --type=LoadBalancer --port 80 --target-port 8081

kubectl get service orders

sleep 45

echo "http://$(kubectl get service orders -o=jsonpath='{.status.loadBalancer.ingress[0].ip}')"

ORDERS_IP_ADDRESS=$(kubectl get service orders -o=jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "http://$ORDERS_IP_ADDRESS"

cat > .env.monolith <<EOF_CP
REACT_APP_ORDERS_URL=http://$ORDERS_IP_ADDRESS/api/orders
REACT_APP_PRODUCTS_URL=/service/products
EOF_CP

npm run build:monolith

cd ~/monolith-to-microservices/monolith
gcloud builds submit --tag gcr.io/${GOOGLE_CLOUD_PROJECT}/monolith:2.0.0 .

kubectl set image deployment/monolith monolith=gcr.io/${GOOGLE_CLOUD_PROJECT}/monolith:2.0.0

sleep 10

kubectl set image deployment/monolith monolith=gcr.io/${GOOGLE_CLOUD_PROJECT}/monolith:2.0.0

cd ~/monolith-to-microservices/microservices/src/products
gcloud builds submit --tag gcr.io/${GOOGLE_CLOUD_PROJECT}/products:1.0.0 .

kubectl create deployment products --image=gcr.io/${GOOGLE_CLOUD_PROJECT}/products:1.0.0

kubectl expose deployment products --type=LoadBalancer --port 80 --target-port 8082

kubectl get service products

sleep 30

echo "http://$(kubectl get service products -o=jsonpath='{.status.loadBalancer.ingress[0].ip}')"

ORDERS_IP_ADDRESS=$(kubectl get service orders -o=jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "http://$ORDERS_IP_ADDRESS"

PRODUCTS_IP_ADDRESS=$(kubectl get service products -o=jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "http://$PRODUCTS_IP_ADDRESS"

cat > .env.monolith <<EOF_CP
REACT_APP_ORDERS_URL=http://$ORDERS_IP_ADDRESS/api/orders
REACT_APP_PRODUCTS_URL=http://$PRODUCTS_IP_ADDRESS/api/products
EOF_CP

npm run build:monolith

cd ~/monolith-to-microservices/monolith
gcloud builds submit --tag gcr.io/${GOOGLE_CLOUD_PROJECT}/monolith:3.0.0 .

kubectl set image deployment/monolith monolith=gcr.io/${GOOGLE_CLOUD_PROJECT}/monolith:3.0.0

cd ~/monolith-to-microservices/react-app
cp .env.monolith .env
npm run build

cd ~/monolith-to-microservices/microservices/src/frontend
gcloud builds submit --tag gcr.io/${GOOGLE_CLOUD_PROJECT}/frontend:1.0.0 .

kubectl create deployment frontend --image=gcr.io/${GOOGLE_CLOUD_PROJECT}/frontend:1.0.0

kubectl expose deployment frontend --type=LoadBalancer --port 80 --target-port 8080

echo "${BG_RED}${BOLD}Congratulations For Completing The Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#