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

export SERVICE_NAME=netflix-dataset-service

export FRNT_STG_SRV=frontend-staging-service

export FRNT_PRD_SRV=frontend-production-service

gcloud config set project $(gcloud projects list --format='value(PROJECT_ID)' --filter='qwiklabs-gcp')

gcloud services enable run.googleapis.com

gcloud firestore databases create --location=$REGION

git clone https://github.com/rosera/pet-theory.git

cd pet-theory/lab06/firebase-import-csv/solution
npm install
node index.js netflix_titles_original.csv

cd ~/pet-theory/lab06/firebase-rest-api/solution-01
npm install
gcloud builds submit --tag gcr.io/$GOOGLE_CLOUD_PROJECT/rest-api:0.1
gcloud beta run deploy $SERVICE_NAME --image gcr.io/$GOOGLE_CLOUD_PROJECT/rest-api:0.1 --allow-unauthenticated --region=$REGION

cd ~/pet-theory/lab06/firebase-rest-api/solution-02
npm install
gcloud builds submit --tag gcr.io/$GOOGLE_CLOUD_PROJECT/rest-api:0.2
gcloud beta run deploy $SERVICE_NAME --image gcr.io/$GOOGLE_CLOUD_PROJECT/rest-api:0.2 --allow-unauthenticated --region=$REGION

SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --platform=managed --region=$REGION --format="value(status.url)")

curl -X GET $SERVICE_URL/2019

cd ~/pet-theory/lab06/firebase-frontend/public

sed -i 's/^const REST_API_SERVICE = "data\/netflix\.json"/\/\/ const REST_API_SERVICE = "data\/netflix.json"/' app.js

sed -i "1i const REST_API_SERVICE = \"$SERVICE_URL/2020\"" app.js

npm install
cd ~/pet-theory/lab06/firebase-frontend
gcloud builds submit --tag gcr.io/$GOOGLE_CLOUD_PROJECT/frontend-staging:0.1
gcloud beta run deploy $FRNT_STG_SRV --image gcr.io/$GOOGLE_CLOUD_PROJECT/frontend-staging:0.1 --region=$REGION --quiet

gcloud builds submit --tag gcr.io/$GOOGLE_CLOUD_PROJECT/frontend-production:0.1
gcloud beta run deploy $FRNT_PRD_SRV --image gcr.io/$GOOGLE_CLOUD_PROJECT/frontend-production:0.1 --region=$REGION --quiet

echo "${RED}${BOLD}Congratulations${RESET}" "${WHITE}${BOLD}for${RESET}" "${GREEN}${BOLD}Completing the Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#