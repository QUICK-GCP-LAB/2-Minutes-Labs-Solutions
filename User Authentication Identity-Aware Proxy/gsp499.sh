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

gcloud services enable iap.googleapis.com

gcloud auth list

gcloud config list project

gsutil cp gs://spls/gsp499/user-authentication-with-iap.zip .

unzip user-authentication-with-iap.zip

cd user-authentication-with-iap

gcloud services enable appengineflex.googleapis.com

cd 1-HelloWorld

sed -i 's/python37/python39/g' app.yaml

gcloud app create --region=$REGION

deploy_function() {
  yes | gcloud app deploy
}

deploy_success=false

while [ "$deploy_success" = false ]; do
  if deploy_function; then
    echo "Function deployed successfully."
    deploy_success=true
  else
    echo "Retrying..."
    sleep 10
  fi
done

cd ~/user-authentication-with-iap/2-HelloUser

sed -i 's/python37/python39/g' app.yaml

deploy_function() {
  yes | gcloud app deploy
}

deploy_success=false

while [ "$deploy_success" = false ]; do
  if deploy_function; then
    echo "Function deployed successfully."
    deploy_success=true
  else
    echo "Retrying..."
    sleep 10
  fi
done

cd ~/user-authentication-with-iap/3-HelloVerifiedUser

sed -i 's/python37/python39/g' app.yaml

deploy_function() {
  yes | gcloud app deploy
}

deploy_success=false

while [ "$deploy_success" = false ]; do
  if deploy_function; then
    echo "Function deployed successfully."
    deploy_success=true
  else
    echo "Retrying..."
    sleep 10
  fi
done

EMAIL="$(gcloud config get-value core/account)" # This uses your current user/email

LINK=$(gcloud app browse)

LINKU=${LINK#https://}

cat > details.json << EOF
{
  App name: IAP Example
  Application home page: $LINK
  Application privacy Policy link: $LINK/privacy
  Authorized domains: $LINKU
  Developer Contact Information: $EMAIL
}
EOF

cat details.json

echo "${BG_RED}${BOLD}Congratulations For Completing The Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#
