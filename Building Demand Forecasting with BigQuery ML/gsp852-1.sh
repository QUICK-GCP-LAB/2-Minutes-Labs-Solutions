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

bq query --use_legacy_sql=false "SELECT bikeid, starttime, start_station_name, end_station_name FROM \`bigquery-public-data.new_york_citibike.citibike_trips\` WHERE starttime IS NOT NULL LIMIT 5;"

bq query --use_legacy_sql=false "SELECT EXTRACT(DATE FROM TIMESTAMP(starttime)) AS start_date, start_station_id, COUNT(*) AS total_trips FROM \`bigquery-public-data.new_york_citibike.citibike_trips\` WHERE starttime BETWEEN DATE('2016-01-01') AND DATE('2017-01-01') GROUP BY start_station_id, start_date LIMIT 5;"

bq --location=US mk --dataset --default_table_expiration=86400 --description "bqmlforecast dataset" $DEVSHELL_PROJECT_ID:bqmlforecast

echo "${YELLOW}${BOLD}Now Create the table${RESET}"