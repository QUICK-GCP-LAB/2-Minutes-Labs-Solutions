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

export PROJECT_ID=$(gcloud info --format='value(config.project)')

bq mk fruit_store

bq mk --table --description "Table for fruit details" $DEVSHELL_PROJECT_ID:fruit_store.fruit_details

bq load --source_format=NEWLINE_DELIMITED_JSON --autodetect $DEVSHELL_PROJECT_ID:fruit_store.fruit_details gs://data-insights-course/labs/optimizing-for-performance/shopping_cart.json

echo "${GREEN}${BOLD}Task 2. Practice working with arrays in SQL Completed ${RESET}"

bq query --use_legacy_sql=false \
"
SELECT
  fullVisitorId,
  date,
  ARRAY_AGG(DISTINCT v2ProductName) AS products_viewed,
  ARRAY_LENGTH(ARRAY_AGG(DISTINCT v2ProductName)) AS distinct_products_viewed,
  ARRAY_AGG(DISTINCT pageTitle) AS pages_viewed,
  ARRAY_LENGTH(ARRAY_AGG(DISTINCT pageTitle)) AS distinct_pages_viewed
  FROM \`data-to-insights.ecommerce.all_sessions\`
WHERE visitId = 1501570398
GROUP BY fullVisitorId, date
ORDER BY date
"

echo "${GREEN}${BOLD}Task 3. Create your own arrays with ARRAY_AGG() Completed${RESET}"

bq query --use_legacy_sql=false \
"
SELECT DISTINCT
  visitId,
  h.page.pageTitle
FROM \`bigquery-public-data.google_analytics_sample.ga_sessions_20170801\`,
UNNEST(hits) AS h
WHERE visitId = 1501570398
LIMIT 10
"

echo "${GREEN}${BOLD}Task 4. Query tables containing arrays Completed${RESET}"

echo '[
    {
        "name": "race",
        "type": "STRING",
        "mode": "NULLABLE"
    },
    {
        "name": "participants",
        "type": "RECORD",
        "mode": "REPEATED",
        "fields": [
            {
                "name": "name",
                "type": "STRING",
                "mode": "NULLABLE"
            },
            {
                "name": "splits",
                "type": "FLOAT",
                "mode": "REPEATED"
            }
        ]
    }
]' > schema.json


bq mk racing

bq mk --table --schema=schema.json --description "Table for race details" $DEVSHELL_PROJECT_ID:racing.race_results 

bq load --source_format=NEWLINE_DELIMITED_JSON --schema=schema.json $DEVSHELL_PROJECT_ID:racing.race_results gs://data-insights-course/labs/optimizing-for-performance/race_results.json

echo "${GREEN}${BOLD}Task 6. Practice with STRUCTs and arrays Completed${RESET}"

bq query --use_legacy_sql=false \
"
#standardSQL
SELECT COUNT(p.name) AS racer_count
FROM racing.race_results AS r, UNNEST(r.participants) AS p
"

echo "${GREEN}${BOLD}Task 7. Lab question: STRUCT() Completed${RESET}"

bq query --use_legacy_sql=false \
"
#standardSQL
SELECT
  p.name,
  SUM(split_times) as total_race_time
FROM racing.race_results AS r
, UNNEST(r.participants) AS p
, UNNEST(p.splits) AS split_times
WHERE p.name LIKE 'R%'
GROUP BY p.name
ORDER BY total_race_time ASC;
"

echo "${GREEN}${BOLD}Task 8. Lab question: Unpacking arrays with UNNEST( ) Completed${RESET}"

bq query --use_legacy_sql=false \
"
#standardSQL
SELECT
  p.name,
  split_time
FROM racing.race_results AS r
, UNNEST(r.participants) AS p
, UNNEST(p.splits) AS split_time
WHERE split_time = 23.2;
"

echo "${GREEN}${BOLD}Task 9. Filter within array values Completed${RESET}"

echo "${RED}${BOLD}Congratulations${RESET}" "${WHITE}${BOLD}for${RESET}" "${GREEN}${BOLD}Completing the Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#
