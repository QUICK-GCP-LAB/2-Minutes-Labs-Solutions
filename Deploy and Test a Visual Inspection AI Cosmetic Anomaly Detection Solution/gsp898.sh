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

cat > prepare_disk.sh <<'EOF_END'

export DOCKER_TAG=gcr.io/ql-shared-resources-test/defect_solution@sha256:776fd8c65304ac017f5b9a986a1b8189695b7abbff6aa0e4ef693c46c7122f4c

export VISERVING_CPU_DOCKER_WITH_MODEL=${DOCKER_TAG}
export HTTP_PORT=8602
export LOCAL_METRIC_PORT=8603

docker pull ${VISERVING_CPU_DOCKER_WITH_MODEL}

docker run -v /secrets:/secrets --rm -d --name "test_cpu" \
--network="host" \
-p ${HTTP_PORT}:8602 \
-p ${LOCAL_METRIC_PORT}:8603 \
-t ${VISERVING_CPU_DOCKER_WITH_MODEL} \
--metric_project_id="${PROJECT_ID}" \
--use_default_credentials=false \
--service_account_credentials_json=/secrets/assembly-usage-reporter.json

gsutil cp gs://cloud-training/gsp895/prediction_script.py .

export PROJECT_ID=$(gcloud config get-value core/project)
gsutil mb gs://${PROJECT_ID}
gsutil -m cp gs://cloud-training/gsp897/cosmetic-test-data/*.png \
gs://${PROJECT_ID}/cosmetic-test-data/
gsutil cp gs://${PROJECT_ID}/cosmetic-test-data/IMG_07703.png .

sudo apt install python3 -y
sudo apt install python3-pip -y
sudo apt install python3.11-venv -y 
python3 -m venv create myvenv
source myvenv/bin/activate
pip install absl-py  
pip install numpy 
pip install requests

python3 ./prediction_script.py --input_image_file=./IMG_07703.png  --port=8602 --output_result_file=def_prediction_result.json

python3 ./prediction_script.py --input_image_file=./IMG_07703.png  --port=8602 --num_of_requests=10 --output_result_file=def_latency_result.json

export PROJECT_ID=$(gcloud config get-value core/project)
gsutil cp gs://${PROJECT_ID}/cosmetic-test-data/IMG_0769.png .

python3 ./prediction_script.py --input_image_file=./IMG_0769.png  --port=8602 --output_result_file=non_def_prediction_result.json

python3 ./prediction_script.py --input_image_file=./IMG_0769.png  --port=8602 --num_of_requests=10 --output_result_file=non_def_latency_result.json

EOF_END

export ZONE=$(gcloud compute instances list lab-vm --format 'csv[no-heading](zone)')

gcloud compute scp prepare_disk.sh lab-vm:/tmp --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet

gcloud compute ssh lab-vm --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet --command="bash /tmp/prepare_disk.sh"

echo "${BG_RED}${BOLD}Congratulations For Completing The Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#
