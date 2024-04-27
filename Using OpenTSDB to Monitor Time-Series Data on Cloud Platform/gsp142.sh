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

gcloud config set compute/zone $ZONE

git clone https://github.com/GoogleCloudPlatform/opentsdb-bigtable.git

cd opentsdb-bigtable

gcloud container clusters create opentsdb-cluster \
--zone=$ZONE \
--machine-type e2-standard-4 \
--scopes "https://www.googleapis.com/auth/cloud-platform"

export PROJECT_ID=$(gcloud config get project)
export REGION="${ZONE%-*}"
export AR_REPO=opentsdb-bt-repo
export BIGTABLE_INSTANCE_ID=bt-opentsdb
export ZONE=$ZONE

gcloud artifacts repositories create ${AR_REPO} \
    --repository-format=docker  \
    --location=${REGION} \
    --description="OpenTSDB on bigtable container images"

export SERVER_IMAGE_NAME=opentsdb-server-bigtable
export SERVER_IMAGE_TAG=2.4.1

gcloud builds submit \
    --tag ${REGION}-docker.pkg.dev/${PROJECT_ID}/${AR_REPO}/${SERVER_IMAGE_NAME}:${SERVER_IMAGE_TAG} \
    build

export GEN_IMAGE_NAME=opentsdb-timeseries-generate
export GEN_IMAGE_TAG=0.1

cd generate-ts
./build-cloud.sh
cd ..

envsubst < configmaps/opentsdb-config.yaml.tpl | kubectl create -f -

envsubst < jobs/opentsdb-init.yaml.tpl | kubectl create -f -

kubectl describe jobs

sleep 60

OPENTSDB_INIT_POD=$(kubectl get pods --selector=job-name=opentsdb-init \
                    --output=jsonpath={.items..metadata.name})
kubectl logs $OPENTSDB_INIT_POD


envsubst < deployments/opentsdb-write.yaml.tpl | kubectl create -f  -

envsubst < deployments/opentsdb-read.yaml.tpl | kubectl create -f  -

kubectl get pods

kubectl create -f services/opentsdb-write.yaml

kubectl create -f services/opentsdb-read.yaml

kubectl get services

envsubst < deployments/generate.yaml.tpl | kubectl create -f -

kubectl create -f configmaps/grafana.yaml

kubectl create -f deployments/grafana.yaml

echo "${RED}${BOLD}Congratulations${RESET}" "${WHITE}${BOLD}for${RESET}" "${GREEN}${BOLD}Completing the Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#