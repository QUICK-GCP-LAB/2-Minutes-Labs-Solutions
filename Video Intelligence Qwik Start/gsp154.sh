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

gcloud iam service-accounts create quickstart

gcloud iam service-accounts keys create key.json --iam-account quickstart@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com

gcloud auth activate-service-account --key-file key.json

gcloud auth print-access-token

cat > request.json <<EOF
{
   "inputUri":"gs://spls/gsp154/video/train.mp4",
   "features": [
       "LABEL_DETECTION"
   ]
}
EOF

# Run the initial annotation request
response=$(curl -s -H 'Content-Type: application/json' \
    -H 'Authorization: Bearer '$(gcloud auth print-access-token)'' \
    'https://videointelligence.googleapis.com/v1/videos:annotate' \
    -d @request.json)

# Extract the project ID, location, and operation name from the response using jq
project_id=$(echo $response | jq -r '.name' | cut -d'/' -f2)
location=$(echo $response | jq -r '.name' | cut -d'/' -f4)
operation_name=$(echo $response | jq -r '.name' | cut -d'/' -f6)

# Use the extracted values in the subsequent command
curl -s -H 'Content-Type: application/json' \
    -H 'Authorization: Bearer '$(gcloud auth print-access-token)'' \
    "https://videointelligence.googleapis.com/v1/projects/$project_id/locations/$location/operations/$operation_name"

echo "${RED}${BOLD}Congratulations${RESET}" "${WHITE}${BOLD}for${RESET}" "${GREEN}${BOLD}Completing the Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#