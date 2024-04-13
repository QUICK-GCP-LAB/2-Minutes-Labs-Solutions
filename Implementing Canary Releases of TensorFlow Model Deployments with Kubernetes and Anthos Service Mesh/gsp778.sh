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

gcloud auth list 

cd
SRC_REPO=https://github.com/GoogleCloudPlatform/mlops-on-gcp
kpt pkg get $SRC_REPO/workshops/mlep-qwiklabs/tfserving-canary-gke tfserving-canary

export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_NUMBER=$(gcloud projects describe ${PROJECT_ID} \
    --format="value(projectNumber)")
export CLUSTER_NAME=cluster-1
export WORKLOAD_POOL=${PROJECT_ID}.svc.id.goog
export MESH_ID="proj-${PROJECT_NUMBER}"


gcloud config set compute/zone ${ZONE}
gcloud beta container clusters create ${CLUSTER_NAME} \
    --machine-type=e2-standard-4 \
    --num-nodes=5 \
    --workload-pool=${WORKLOAD_POOL} \
    --logging=SYSTEM,WORKLOAD \
    --monitoring=SYSTEM \
    --subnetwork=default \
    --release-channel=stable \
    --labels mesh_id=${MESH_ID}

kubectl create clusterrolebinding cluster-admin-binding   --clusterrole=cluster-admin   --user=$(whoami)@qwiklabs.net

curl https://storage.googleapis.com/csm-artifacts/asm/asmcli_1.15 > asmcli

chmod +x asmcli

./asmcli install \
  --project_id $PROJECT_ID \
  --cluster_name $CLUSTER_NAME \
  --cluster_location $ZONE \
  --fleet_id $PROJECT_ID \
  --output_dir ./asm_output \
  --enable_all \
  --option legacy-default-ingressgateway \
  --ca mesh_ca \
  --enable_gcp_components

GATEWAY_NS=istio-gateway
kubectl create namespace $GATEWAY_NS

REVISION=$(kubectl get deploy -n istio-system -l app=istiod -o \
jsonpath={.items[*].metadata.labels.'istio\.io\/rev'}'{"\n"}')

kubectl label namespace $GATEWAY_NS \
istio.io/rev=$REVISION --overwrite

cd ~/asm_output

kubectl apply -n $GATEWAY_NS \
  -f samples/gateways/istio-ingressgateway/autoscalingv2


kubectl label namespace default istio-injection- istio.io/rev=$REVISION --overwrite

export MODEL_BUCKET=${PROJECT_ID}-bucket
gsutil mb gs://${MODEL_BUCKET}

gsutil cp -r gs://spls/gsp778/resnet_101 gs://${MODEL_BUCKET}
gsutil cp -r gs://spls/gsp778/resnet_50 gs://${MODEL_BUCKET}

gsutil uniformbucketlevelaccess set on gs://${MODEL_BUCKET}

gsutil iam ch allUsers:objectViewer gs://${MODEL_BUCKET}

cd ~/tfserving-canary

sed -i "s@\[YOUR_BUCKET\]@$MODEL_BUCKET@g" tf-serving/configmap-resnet50.yaml

kubectl apply -f tf-serving/configmap-resnet50.yaml

cat tf-serving/deployment-resnet50.yaml

kubectl apply -f tf-serving/deployment-resnet50.yaml

kubectl get deployments

kubectl apply -f tf-serving/service.yaml

kubectl apply -f tf-serving/gateway.yaml

kubectl apply -f tf-serving/virtualservice.yaml

export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].port}')

export GATEWAY_URL=$INGRESS_HOST:$INGRESS_PORT
echo $GATEWAY_URL

curl -d @payloads/request-body.json -X POST http://$GATEWAY_URL/v1/models/image_classifier:predict

kubectl apply -f tf-serving/destinationrule.yaml

kubectl apply -f tf-serving/virtualservice-weight-100.yaml

cd ~/tfserving-canary

sed -i "s@\[YOUR_BUCKET\]@$MODEL_BUCKET@g" tf-serving/configmap-resnet101.yaml

kubectl apply -f tf-serving/configmap-resnet101.yaml

kubectl apply -f tf-serving/deployment-resnet101.yaml

kubectl apply -f tf-serving/virtualservice-weight-70.yaml

kubectl apply -f tf-serving/virtualservice-focused-routing.yaml

echo "${RED}${BOLD}Congratulations${RESET}" "${WHITE}${BOLD}for${RESET}" "${GREEN}${BOLD}Completing the Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#