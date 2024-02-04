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

echo "${YELLOW}${BOLD}

Starting Execution 

${RESET}"

# Run In 2nd Project

export REGION="${ZONE%-*}"

gsutil mb -p $DEVSHELL_PROJECT_ID -c STANDARD -l $REGION -b on gs://$DEVSHELL_PROJECT_ID-2

gsutil uniformbucketlevelaccess set off gs://$DEVSHELL_PROJECT_ID-2

echo "Awesome Solution by quick gcp lab" > test.txt

gsutil cp test.txt gs://$DEVSHELL_PROJECT_ID-2


# Create the service account
gcloud iam service-accounts create cross-project-storage --display-name "Cross-Project Storage Account"

# Grant Storage Object Viewer role to the service account
gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID --member="serviceAccount:cross-project-storage@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com" --role="roles/storage.objectViewer"

gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID --member="serviceAccount:cross-project-storage@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com" --role="roles/storage.objectAdmin"

# Generate and download the JSON key file
gcloud iam service-accounts keys create credentials.json --iam-account=cross-project-storage@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com

echo "${GREEN}${BOLD}

Task 8. Cross-project sharing Completed

${RESET}"

echo "${RED}${BOLD}

Congratulations for Completing the Lab !!!

${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#