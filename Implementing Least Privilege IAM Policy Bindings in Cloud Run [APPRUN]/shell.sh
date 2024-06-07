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

gcloud services enable run.googleapis.com

gcloud config set run/region $REGION

 gcloud run deploy billing-service \
  --image gcr.io/qwiklabs-resources/gsp723-parking-service \
  --region $REGION \
  --allow-unauthenticated

 BILLING_SERVICE_URL=$(gcloud run services list \
  --format='value(URL)' \
  --filter="billing-service")

curl -X POST -H "Content-Type: application/json" $BILLING_SERVICE_URL -d '{"userid": "1234", "minBalance": 100}'

gcloud run deploy billing-service \
  --image gcr.io/qwiklabs-resources/gsp723-parking-service \
  --region $REGION \
  --no-allow-unauthenticated

curl -X POST -H "Content-Type: application/json" $BILLING_SERVICE_URL -d '{"userid": "1234", "minBalance": 100}'

gcloud iam service-accounts create billing-initiator --display-name="Billing Initiator"

gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID --member="serviceAccount:billing-initiator@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com" --role="roles/run.invoker"

 BILLING_INITIATOR_EMAIL=$(gcloud iam service-accounts list --filter="Billing Initiator" --format="value(EMAIL)"); echo $BILLING_INITIATOR_EMAIL

gcloud run services add-iam-policy-binding billing-service --region $REGION \
  --member=serviceAccount:${BILLING_INITIATOR_EMAIL} \
  --role=roles/run.invoker --platform managed

# 2nd cloud shell

BILLING_INITIATOR_EMAIL=$(gcloud iam service-accounts list --filter="Billing Initiator" --format="value(EMAIL)"); echo $BILLING_INITIATOR_EMAIL

BILLING_SERVICE_URL=$(gcloud run services list \
  --format='value(URL)' \
  --filter="billing-service")

gcloud iam service-accounts keys create key.json --iam-account=${BILLING_INITIATOR_EMAIL}

gcloud auth activate-service-account --key-file=key.json

curl -X POST -H "Content-Type: application/json" \
  -H "Authorization: Bearer $(gcloud auth print-identity-token)" \
  $BILLING_SERVICE_URL -d '{"userid": "1234", "minBalance": 500}'

curl -X POST -H "Content-Type: application/json" \
  -H "Authorization: Bearer $(gcloud auth print-identity-token)" \
  $BILLING_SERVICE_URL -d '{"userid": "1234", "minBalance": 700}'

## 3rd cloud shell

gcloud run deploy billing-service-2 \
  --image gcr.io/qwiklabs-resources/gsp723-parking-service \
  --region $REGION \
  --no-allow-unauthenticated

BILLING_SERVICE_2_URL=$(gcloud run services list \
  --format='value(URL)' \
  --filter="billing-service-2")

gcloud auth activate-service-account --key-file=key.json

curl -X POST -H "Content-Type: application/json" \
  -H "Authorization: Bearer $(gcloud auth print-identity-token)" \
  $BILLING_SERVICE_2_URL -d '{"userid": "1234", "minBalance": 900}'

curl -X POST -H "Content-Type: application/json" \
  -H "Authorization: Bearer $(gcloud auth print-identity-token)" \
  $BILLING_SERVICE_2_URL -d '{"userid": "1234", "minBalance": 500}'

echo "${RED}${BOLD}Congratulations${RESET}" "${WHITE}${BOLD}for${RESET}" "${GREEN}${BOLD}Completing the Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#