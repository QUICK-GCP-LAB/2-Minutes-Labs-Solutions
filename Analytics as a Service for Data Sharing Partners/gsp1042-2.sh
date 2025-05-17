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

# Step 1: Prompt for project environment variables
echo "${BOLD}${CYAN}Setting Project Environment Variables${RESET}"
read -p "Enter PROJECT_ID value: " PROJECT_ID
export PROJECT_ID

# Step 2: Creating customer A view
echo "${BOLD}${RED}Creating customer A view${RESET}"
bq query --use_legacy_sql=false \
"CREATE OR REPLACE VIEW \`${DEVSHELL_PROJECT_ID}.customer_a_dataset.customer_a_table\` AS
SELECT geos.zip_code, geos.city, cust.last_name, cust.first_name
FROM \`${DEVSHELL_PROJECT_ID}.customer_a_dataset.customer_info\` AS cust
JOIN \`${PROJECT_ID}.demo_dataset.authorized_view_a\` AS geos
ON geos.zip_code = cust.postal_code;"

echo

echo "${BOLD}${BLUE}Click here: ${RESET}""https://lookerstudio.google.com/navigation/reporting"

echo

echo "${BOLD}${BLUE}Now, login with Customer B Project Console user credential${RESET}"