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


# Step 1: Prompt for user environment variables
echo "${BOLD}${GREEN}Setting User Environment Variables${RESET}"
set_users_env() {
  echo
  read -p "${BOLD}${BLUE}Enter User A value: ${RESET}" USER_A
  echo
  read -p "${BOLD}${MAGENTA}Enter User B value: ${RESET}" USER_B
  export USER_A USER_B
  echo
  echo "${BOLD}${CYAN}Thank you for providing the user information!${RESET}"
  echo
}

set_users_env

# Step 2: Create BigQuery view for Texas zip codes
echo "${BOLD}${MAGENTA}Creating BigQuery view for Texas zip codes${RESET}"
bq mk --use_legacy_sql=false \
--view='SELECT * FROM `bigquery-public-data.geo_us_boundaries.zip_codes` WHERE state_code="TX" LIMIT 4000' \
demo_dataset.authorized_view_a

# Step 3: Creating access policy for authorized view A
echo "${BOLD}${CYAN}Creating access policy for authorized view A${RESET}"
cat <<EOF > access_policy.json
{
  "access": [
    {
      "role": "OWNER",
      "specialGroup": "projectOwners"
    },
    {
      "role": "READER",
      "specialGroup": "projectWriters"
    },
    {
      "role": "READER",
      "specialGroup": "projectReaders"
    },
    {
      "view": {
        "projectId": "$DEVSHELL_PROJECT_ID",
        "datasetId": "demo_dataset",
        "tableId": "authorized_view_a"
      }
    }
  ]
}
EOF

# Step 4: Update BigQuery dataset with access policy
echo "${BOLD}${RED}Updating BigQuery dataset with access policy${RESET}"
bq update --source access_policy.json "$DEVSHELL_PROJECT_ID:demo_dataset"

# Step 5: Create BigQuery view for California zip codes
echo "${BOLD}${BLUE}Creating BigQuery view for California zip codes${RESET}"
bq mk --use_legacy_sql=false \
--view='SELECT * FROM `bigquery-public-data.geo_us_boundaries.zip_codes` WHERE state_code="CA" LIMIT 4000' \
demo_dataset.authorized_view_b

# Step 6: Creating access policy for authorized view B
echo "${BOLD}${YELLOW}Creating access policy for authorized view B${RESET}"
cat <<EOF > access_policy.json
{
  "access": [
    {
      "role": "OWNER",
      "specialGroup": "projectOwners"
    },
    {
      "role": "READER",
      "specialGroup": "projectWriters"
    },
    {
      "role": "READER",
      "specialGroup": "projectReaders"
    },
    {
      "view": {
        "projectId": "$DEVSHELL_PROJECT_ID",
        "datasetId": "demo_dataset",
        "tableId": "authorized_view_a"
      }
    },
    {
      "view": {
        "projectId": "$DEVSHELL_PROJECT_ID",
        "datasetId": "demo_dataset",
        "tableId": "authorized_view_b"
      }
    }
  ]
}
EOF

# Step 7: Update BigQuery dataset with access policy for view B
echo "${BOLD}${MAGENTA}Updating BigQuery dataset with access policy for view B${RESET}"
bq update --source access_policy.json "$DEVSHELL_PROJECT_ID:demo_dataset"

# Step 8: Creating policy file for User A
echo "${BOLD}${CYAN}Creating IAM policy for User A${RESET}"
cat <<EOF > policy.json
{
  "bindings": [
    {
      "role": "roles/bigquery.dataViewer",
      "members": [
        "user:$USER_A"
      ]
    }
  ]
}
EOF

bq set-iam-policy demo_dataset.authorized_view_a policy.json


# Step 9: Creating policy file for User B
echo "${BOLD}${GREEN}Creating IAM policy for User B${RESET}"
cat <<EOF > policy.json
{
  "bindings": [
    {
      "role": "roles/bigquery.dataViewer",
      "members": [
        "user:$USER_B"
      ]
    }
  ]
}
EOF

bq set-iam-policy demo_dataset.authorized_view_b policy.json

echo

echo "${BOLD}${BLUE}Now, login with Customer A Project Console user credential${RESET}"