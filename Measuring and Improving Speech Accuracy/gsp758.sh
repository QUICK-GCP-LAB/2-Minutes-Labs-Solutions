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

gcloud services enable notebooks.googleapis.com

gcloud services enable aiplatform.googleapis.com

gsutil mb gs://$DEVSHELL_PROJECT_ID

cat > startup-script.sh <<EOF_END
#!/bin/bash

# Copy notebooks
gsutil cp gs://spls/gsp758/notebook/measuring-accuracy.ipynb .
gsutil cp gs://spls/gsp758/notebook/speech_adaptation.ipynb .
gsutil cp gs://spls/gsp758/notebook/simple_wer_v2.py .

# Run the notebooks
jupyter nbconvert --to notebook --execute measuring-accuracy.ipynb
jupyter nbconvert --to notebook --execute speech_adaptation.ipynb

EOF_END

export REGION="${ZONE%-*}"
export NOTEBOOK_NAME="awesome-jupyter"
export MACHINE_TYPE="e2-standard-2"
export STARTUP_SCRIPT_URL="gs://$DEVSHELL_PROJECT_ID/startup-script.sh"

gcloud compute images list --project=deeplearning-platform-release --no-standard-images --filter="name~'tf2-ent-2-1'"

gcloud notebooks instances create $NOTEBOOK_NAME \
  --location=$ZONE \
  --vm-image-project=deeplearning-platform-release \
  --vm-image-family=tf-2-11-cu113-notebooks \
  --machine-type=$MACHINE_TYPE \
  --metadata=startup-script-url=gs://$DEVSHELL_PROJECT_ID/startup-script.sh

echo "${RED}${BOLD}Congratulations${RESET}" "${WHITE}${BOLD}for${RESET}" "${GREEN}${BOLD}Completing the Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#