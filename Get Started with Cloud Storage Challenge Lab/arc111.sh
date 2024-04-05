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

#form 1
# Function to run form 1 code
run_form_1() {
export BUCKET="$(gcloud config get-value project)"		

gsutil mb -p $BUCKET gs://$BUCKET-bucket

gsutil retention set 30s gs://$BUCKET-gcs-bucket

echo "Awesome Lab" > sample.txt

gsutil cp sample.txt gs://$BUCKET-bucket-ops/
}



#form 2
# Function to run form 2 code
run_form_2() {
export BUCKET="$(gcloud config get-value project)"		

gsutil mb -c nearline gs://$BUCKET-bucket

gcloud alpha storage buckets update gs://$BUCKET-gcs-bucket --no-uniform-bucket-level-access

gsutil acl ch -u $USER_EMAIL:OWNER gs://$BUCKET-gcs-bucket

gsutil rm gs://$BUCKET-gcs-bucket/sample.txt

echo "Awesome Lab" > sample.txt

gsutil cp sample.txt gs://$BUCKET-gcs-bucket

gsutil acl ch -u allUsers:R gs://$BUCKET-gcs-bucket/sample.txt

gcloud storage buckets update gs://$BUCKET-bucket-ops --update-labels=key=value
}


#form 3
# Function to run form 3 code
run_form_3() {
export BUCKET="$(gcloud config get-value project)"		


gsutil mb -c coldline gs://$BUCKET-bucket

echo "This is an example of editing the file content for cloud storage object" | gsutil cp - gs://$BUCKET-gcs-bucket/sample.txt

gsutil defstorageclass set ARCHIVE gs://$BUCKET-bucket-ops
}


# Main script block
echo "${WHITE}${BOLD}"

# Get the form number from user input
read -p "Enter lab given Form number (1, 2, or 3): " form_number

# Execute the appropriate function based on the selected form number
case $form_number in
    1) run_form_1 ;;
    2) run_form_2 ;;
    3) run_form_3 ;;
    *) echo "Invalid form number. Please enter 1, 2, or 3." ;;
esac

echo "${RED}${BOLD}Congratulations${RESET}" "${WHITE}${BOLD}for${RESET}" "${GREEN}${BOLD}Completing the Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#