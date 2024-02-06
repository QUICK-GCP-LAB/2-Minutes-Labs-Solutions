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
  #-----------------------------------------------------end----------------------------------------------------------#