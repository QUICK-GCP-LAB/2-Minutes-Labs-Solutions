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

gsutil -m cp -r gs://spls/gsp053/orchestrate-with-kubernetes .

cd orchestrate-with-kubernetes/kubernetes

gcloud container clusters create bootcamp \
  --machine-type e2-small \
  --num-nodes 3 \
  --scopes "https://www.googleapis.com/auth/projecthosting,storage-rw"

sed -i 's/image: "kelseyhightower\/auth:2.0.0"/image: "kelseyhightower\/auth:1.0.0"/' deployments/auth.yaml

kubectl create -f deployments/auth.yaml

kubectl get deployments

kubectl get pods

kubectl create -f services/auth.yaml

kubectl create -f deployments/hello.yaml

kubectl create -f services/hello.yaml

kubectl create secret generic tls-certs --from-file tls/

kubectl create configmap nginx-frontend-conf --from-file=nginx/frontend.conf

kubectl create -f deployments/frontend.yaml

kubectl create -f services/frontend.yaml

kubectl get services frontend

sleep 10

kubectl scale deployment hello --replicas=5

kubectl get pods | grep hello- | wc -l

kubectl scale deployment hello --replicas=3

kubectl get pods | grep hello- | wc -l

sed -i 's/image: "kelseyhightower\/auth:1.0.0"/image: "kelseyhightower\/auth:2.0.0"/' deployments/hello.yaml

kubectl get replicaset

kubectl rollout history deployment/hello

kubectl get pods -o jsonpath --template='{range .items[*]}{.metadata.name}{"\t"}{"\t"}{.spec.containers[0].image}{"\n"}{end}'

kubectl rollout resume deployment/hello

kubectl rollout status deployment/hello

kubectl rollout undo deployment/hello

kubectl rollout history deployment/hello

kubectl get pods -o jsonpath --template='{range .items[*]}{.metadata.name}{"\t"}{"\t"}{.spec.containers[0].image}{"\n"}{end}'

kubectl create -f deployments/hello-canary.yaml

kubectl get deployments

echo "${RED}${BOLD}Congratulations${RESET}" "${WHITE}${BOLD}for${RESET}" "${GREEN}${BOLD}Completing the Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#