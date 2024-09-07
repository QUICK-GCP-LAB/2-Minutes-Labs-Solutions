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

echo "${BG_MAGENTA}${BOLD}Starting Execution${RESET}"v

bq mk Reports

bq query \
  --use_legacy_sql=false \
  --destination_table=$DEVSHELL_PROJECT_ID:Reports.Trees \
  --replace=false \
  --nouse_cache \
  "SELECT
    TIMESTAMP_TRUNC(plant_date, MONTH) as plant_month,
    COUNT(tree_id) AS total_trees,
    species,
    care_taker,
    address,
    site_info
  FROM
    \`bigquery-public-data.san_francisco_trees.street_trees\`
  WHERE
    address IS NOT NULL
    AND plant_date >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 365 DAY)
    AND plant_date < TIMESTAMP_TRUNC(CURRENT_TIMESTAMP(), DAY)
  GROUP BY
    plant_month,
    species,
    care_taker,
    address,
    site_info"

echo "${BG_RED}${BOLD}Congratulations For Completing The Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#