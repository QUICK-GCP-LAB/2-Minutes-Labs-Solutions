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

export PROJECT_ID=$(gcloud config get-value project)
export REGION="${ZONE%-*}"
gcloud config set compute/region $REGION

gcloud services enable \
container.googleapis.com \
clouddeploy.googleapis.com \
artifactregistry.googleapis.com \
cloudbuild.googleapis.com \
clouddeploy.googleapis.com

sleep 30

gcloud container clusters create test --node-locations=$ZONE --num-nodes=1  --async
gcloud container clusters create staging --node-locations=$ZONE --num-nodes=1  --async
gcloud container clusters create prod --node-locations=$ZONE --num-nodes=1  --async

gcloud container clusters list --format="csv(name,status)"

gcloud artifacts repositories create web-app \
--description="Image registry for tutorial web app" \
--repository-format=docker \
--location=$REGION

cd ~/
git clone https://github.com/GoogleCloudPlatform/cloud-deploy-tutorials.git
cd cloud-deploy-tutorials
git checkout c3cae80 --quiet
cd tutorials/base

envsubst < clouddeploy-config/skaffold.yaml.template > web/skaffold.yaml
cat web/skaffold.yaml

cd web
skaffold build --interactive=false \
--default-repo $REGION-docker.pkg.dev/$PROJECT_ID/web-app \
--file-output artifacts.json
cd ..

gcloud artifacts docker images list \
$REGION-docker.pkg.dev/$PROJECT_ID/web-app \
--include-tags \
--format yaml

gcloud config set deploy/region $REGION
cp clouddeploy-config/delivery-pipeline.yaml.template clouddeploy-config/delivery-pipeline.yaml
gcloud beta deploy apply --file=clouddeploy-config/delivery-pipeline.yaml

gcloud beta deploy delivery-pipelines describe web-app

while true; do
  # Get the status of each cluster
  cluster_statuses=$(gcloud container clusters list --format="csv(name,status)" | tail -n +2)

  # Check if all clusters are in RUNNING state
  all_running=true
  while IFS=, read -r cluster_name cluster_status; do
    if [[ "$cluster_status" != "RUNNING" ]]; then
      all_running=false
      break
    fi
  done <<< "$cluster_statuses"

  if $all_running; then
    echo "All clusters are in RUNNING state."
    break
  fi

  # Wait for a short duration before checking again
  sleep 10
done

echo "it's creating now please wait sometimes..."

CONTEXTS=("test" "staging" "prod")
for CONTEXT in ${CONTEXTS[@]}
do
    gcloud container clusters get-credentials ${CONTEXT} --region ${REGION}
    kubectl config rename-context gke_${PROJECT_ID}_${REGION}_${CONTEXT} ${CONTEXT}
done

for CONTEXT in ${CONTEXTS[@]}
do
    kubectl --context ${CONTEXT} apply -f kubernetes-config/web-app-namespace.yaml
done

for CONTEXT in ${CONTEXTS[@]}
do
    envsubst < clouddeploy-config/target-$CONTEXT.yaml.template > clouddeploy-config/target-$CONTEXT.yaml
    gcloud beta deploy apply --file clouddeploy-config/target-$CONTEXT.yaml
done

gcloud beta deploy targets list

gcloud beta deploy releases create web-app-001 \
--delivery-pipeline web-app \
--build-artifacts web/artifacts.json \
--source web/

gcloud beta deploy rollouts list \
--delivery-pipeline web-app \
--release web-app-001

# Wait for the rollout to complete
while true; do
  # Check the rollout status
  status=$(gcloud beta deploy rollouts list --delivery-pipeline web-app --release web-app-001 --format="value(state)" | head -n 1)
  
  # If the status is SUCCESS, break out of the loop
  if [ "$status" == "SUCCEEDED" ]; then
    break
  fi
  
  # Wait for a short duration before checking agai
  echo "it's creating now please wait sometimes..."

  sleep 10
done

# Once the rollout is successful, run the next commands
kubectx test
kubectl get all -n web-app

gcloud beta deploy releases promote \
--delivery-pipeline web-app \
--release web-app-001 \
--quiet

# Wait for the rollout to complete
while true; do
  # Check the rollout status
  status=$(gcloud beta deploy rollouts list --delivery-pipeline web-app --release web-app-001 --format="value(state)" | head -n 1)
  
  # If the status is SUCCESS, break out of the loop
  if [ "$status" == "SUCCEEDED" ]; then
    break
  fi
  
  # Wait for a short duration before checking again
  echo "it's creating now please wait sometimes..."
  sleep 10
done

gcloud beta deploy releases promote \
--delivery-pipeline web-app \
--release web-app-001 \
--quiet


# Wait for the rollout to complete
while true; do
  # Check the rollout status
  status=$(gcloud beta deploy rollouts list --delivery-pipeline web-app --release web-app-001 --format="value(state)" | head -n 1)
  
  # If the status is SUCCESS, break out of the loop
  if [ "$status" == "PENDING_APPROVAL" ]; then
    break
  fi
  
  # Wait for a short duration before checking again
  echo "it's creating now please wait sometimes..."
  sleep 10
done

gcloud beta deploy rollouts approve web-app-001-to-prod-0001 \
--delivery-pipeline web-app \
--release web-app-001 \
--quiet

# Wait for the rollout to complete
while true; do
  # Check the rollout status
  status=$(gcloud beta deploy rollouts list --delivery-pipeline web-app --release web-app-001 --format="value(state)" | head -n 1)
  
  # If the status is SUCCESS, break out of the loop
  if [ "$status" == "SUCCEEDED" ]; then
    break
  fi
  
  # Wait for a short duration before checking again
  echo "it's creating now please wait sometimes..."
  sleep 10
done

kubectx prod
kubectl get all -n web-app

echo "${RED}${BOLD}Congratulations${RESET}" "${WHITE}${BOLD}for${RESET}" "${GREEN}${BOLD}Completing the Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#