clear

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

# Array of color codes excluding black and white
TEXT_COLORS=($RED $GREEN $YELLOW $BLUE $MAGENTA $CYAN)
BG_COLORS=($BG_RED $BG_GREEN $BG_YELLOW $BG_BLUE $BG_MAGENTA $BG_CYAN)

# Pick random colors
RANDOM_TEXT_COLOR=${TEXT_COLORS[$RANDOM % ${#TEXT_COLORS[@]}]}
RANDOM_BG_COLOR=${BG_COLORS[$RANDOM % ${#BG_COLORS[@]}]}

#----------------------------------------------------start--------------------------------------------------#

echo "${RANDOM_BG_COLOR}${RANDOM_TEXT_COLOR}${BOLD}Starting Execution${RESET}"

cat > bank-fullaccess.json <<EOF_END
{
  "name": "bank-fullaccess",
  "displayName": "bank (full access)",
  "approvalType": "auto",
  "attributes": [
    {
      "name": "access",
      "value": "public"
    },
    {
      "name": "full-access",
      "value": "yes"
    }
  ],
  "description": "allows full access to bank API",
  "environments": [
    "eval"
  ],
  "operationGroup": {
    "operationConfigs": [
      {
        "apiSource": "bank-v1",
        "operations": [
          {
            "resource": "/**",
            "methods": [
              "DELETE",
              "GET",
              "PATCH",
              "POST",
              "PUT"
            ]
          }
        ],
        "quota": {
          "limit": "5",
          "interval": "1",
          "timeUnit": "minute"
        }
      }
    ],
    "operationConfigType": "proxy"
  }
}
EOF_END


curl -X POST "https://apigee.googleapis.com/v1/organizations/$DEVSHELL_PROJECT_ID/apiproducts" \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  -d @bank-fullaccess.json

cat > bank-readonly.json <<EOF_END
{
  "name": "bank-readonly",
  "displayName": "bank (read-only)",
  "approvalType": "auto",
  "attributes": [
    {
      "name": "access",
      "value": "public"
    }
  ],
  "description": "allows read-only access to bank API",
  "environments": [
    "eval"
  ],
  "operationGroup": {
    "operationConfigs": [
      {
        "apiSource": "bank-v1",
        "operations": [
          {
            "resource": "/**",
            "methods": [
              "GET"
            ]
          }
        ],
        "quota": {}
      }
    ],
    "operationConfigType": "proxy"
  }
}
EOF_END


curl -X POST "https://apigee.googleapis.com/v1/organizations/$DEVSHELL_PROJECT_ID/apiproducts" \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  -d @bank-readonly.json

curl -X POST "https://apigee.googleapis.com/v1/organizations/$DEVSHELL_PROJECT_ID/developers" \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  -d '{
    "firstName": "Joe",
    "lastName": "Developer",
    "userName": "joe",  
    "email": "joe@example.com"
  }'



export IP_ADDRESS=$(curl -s -H "Authorization: Bearer $(gcloud auth print-access-token)" -X GET "https://apigee.googleapis.com/v1/organizations/${GOOGLE_CLOUD_PROJECT}/envgroups/eval-group" | jq -r '.hostnames[1]')

export URL=https://eval.${IP_ADDRESS}/bank/v1

sed -i 's|<URL>|'"$URL"'|g' simplebank-spec.yaml

cloudshell download simplebank-spec.yaml

