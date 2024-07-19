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

export PROJECT_ID=$(gcloud info --format='value(config.project)')

gsutil mb -l us gs://$DEVSHELL_PROJECT_ID

cat > sample.txt <<EOF_END
Awesome Lab BY quick gcp lab
EOF_END

gsutil cp sample.txt gs://$DEVSHELL_PROJECT_ID


echo "${YELLOW}${BOLD}Task 3. ${RESET}" "${GREEN}${BOLD}Prepare a resource for access testing Completed${RESET}"

gcloud projects remove-iam-policy-binding $DEVSHELL_PROJECT_ID --member=user:$USER_2 --role=roles/viewer


echo "${YELLOW}${BOLD}Task 4. ${RESET}""${GREEN}${BOLD}Remove project access Completed${RESET}"

gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
  --role=roles/storage.objectViewer \
  --member=user:$USER_2

echo "${YELLOW}${BOLD}Task 5. ${RESET}""${GREEN}${BOLD}Add storage access Completed${RESET}"

gcloud iam service-accounts create read-bucket-objects --display-name "read-bucket-objects" 

gcloud iam service-accounts add-iam-policy-binding  read-bucket-objects@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com --member=domain:altostrat.com --role=roles/iam.serviceAccountUser

gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID --member=domain:altostrat.com --role=roles/compute.instanceAdmin.v1

gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID --member="serviceAccount:read-bucket-objects@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com" --role="roles/storage.objectViewer"

gcloud compute instances create demoiam \
  --zone=$ZONE \
  --machine-type=e2-micro \
  --image-family=debian-11 \
  --image-project=debian-cloud \
  --service-account=read-bucket-objects@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com

echo "${YELLOW}${BOLD}Task 6. ${RESET}""${GREEN}${BOLD}Set up the Service Account User Completed${RESET}"

echo "${BG_RED}${BOLD}Congratulations For Completing The Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#
