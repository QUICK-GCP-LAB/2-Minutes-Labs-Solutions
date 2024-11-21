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

export BUCKET_NAME=$DEVSHELL_PROJECT_ID-bucket

export PROJECT_ID=$DEVSHELL_PROJECT_ID

git clone https://github.com/quiccklabs/Redacting-Sensitive-Data-with-Cloud-Data-Loss-Prevention.git

cd Redacting-Sensitive-Data-with-Cloud-Data-Loss-Prevention/quicklabgsp864/samples && npm install

gcloud config set project $PROJECT_ID

gcloud services enable dlp.googleapis.com cloudkms.googleapis.com \
--project $PROJECT_ID

node inspectString.js $PROJECT_ID "My email address is jenny@somedomain.com and you can call me at 555-867-5309" > inspected-string.txt

node inspectFile.js $PROJECT_ID resources/accounts.txt > inspected-file.txt

gsutil cp inspected-string.txt gs://$BUCKET_NAME
gsutil cp inspected-file.txt gs://$BUCKET_NAME

node deidentifyWithMask.js $PROJECT_ID "My order number is F12312399. Email me at anthony@somedomain.com" > de-identify-output.txt

gsutil cp de-identify-output.txt gs://$BUCKET_NAME


node redactText.js $PROJECT_ID  "Please refund the purchase to my credit card 4012888888881881" CREDIT_CARD_NUMBER > redacted-string.txt

node redactImage.js $PROJECT_ID resources/test.png "" PHONE_NUMBER ./redacted-phone.png

node redactImage.js $PROJECT_ID resources/test.png "" EMAIL_ADDRESS ./redacted-email.png

gsutil cp redacted-string.txt gs://$BUCKET_NAME
gsutil cp redacted-phone.png gs://$BUCKET_NAME
gsutil cp redacted-email.png gs://$BUCKET_NAME

echo "${BG_RED}${BOLD}Congratulations For Completing The Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#