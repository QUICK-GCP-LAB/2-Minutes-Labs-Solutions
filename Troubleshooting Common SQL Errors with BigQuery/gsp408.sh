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

echo "${BG_MAGENTA}${BOLD}Starting Execution${RESET}"

export PROJECT_ID=$(gcloud info --format='value(config.project)')

bq query --use_legacy_sql=false \
"
#standardSQL
SELECT
fullVisitorId
FROM \`data-to-insights.ecommerce.rev_transactions\`
"

bq query --use_legacy_sql=false \
"
#standardSQL
SELECT fullVisitorId hits_page_pageTitle
FROM \`data-to-insights.ecommerce.rev_transactions\` LIMIT 1000
"

bq query --use_legacy_sql=false \
"
#standardSQL
SELECT
  fullVisitorId
  , hits_page_pageTitle
FROM \`data-to-insights.ecommerce.rev_transactions\` LIMIT 1000
"

bq query --use_legacy_sql=false \
"
#standardSQL
SELECT
COUNT(DISTINCT fullVisitorId) AS visitor_count
, hits_page_pageTitle
FROM \`data-to-insights.ecommerce.rev_transactions\`
GROUP BY hits_page_pageTitle
"

bq query --use_legacy_sql=false \
"
#standardSQL
SELECT
COUNT(DISTINCT fullVisitorId) AS visitor_count
, hits_page_pageTitle
FROM \`data-to-insights.ecommerce.rev_transactions\`
WHERE hits_page_pageTitle = 'Checkout Confirmation'
GROUP BY hits_page_pageTitle
"

bq query --use_legacy_sql=false \
"
#standardSQL
SELECT
geoNetwork_city,
SUM(totals_transactions) AS totals_transactions,
COUNT( DISTINCT fullVisitorId) AS distinct_visitors
FROM
\`data-to-insights.ecommerce.rev_transactions\`
GROUP BY geoNetwork_city
"

bq query --use_legacy_sql=false \
"
#standardSQL
SELECT
geoNetwork_city,
SUM(totals_transactions) AS totals_transactions,
COUNT( DISTINCT fullVisitorId) AS distinct_visitors
FROM
\`data-to-insights.ecommerce.rev_transactions\`
GROUP BY geoNetwork_city
ORDER BY distinct_visitors DESC
"

bq query --use_legacy_sql=false \
"
#standardSQL
SELECT
geoNetwork_city,
SUM(totals_transactions) AS total_products_ordered,
COUNT( DISTINCT fullVisitorId) AS distinct_visitors,
SUM(totals_transactions) / COUNT( DISTINCT fullVisitorId) AS avg_products_ordered
FROM
\`data-to-insights.ecommerce.rev_transactions\`
GROUP BY geoNetwork_city
ORDER BY avg_products_ordered DESC
"

bq query --use_legacy_sql=false \
"
#standardSQL
SELECT
geoNetwork_city,
SUM(totals_transactions) AS total_products_ordered,
COUNT( DISTINCT fullVisitorId) AS distinct_visitors,
SUM(totals_transactions) / COUNT( DISTINCT fullVisitorId) AS avg_products_ordered
FROM
\`data-to-insights.ecommerce.rev_transactions\`
GROUP BY geoNetwork_city
HAVING avg_products_ordered > 20
ORDER BY avg_products_ordered DESC
"

bq query --use_legacy_sql=false \
"
#standardSQL
SELECT hits_product_v2ProductName, hits_product_v2ProductCategory
FROM \`data-to-insights.ecommerce.rev_transactions\`
GROUP BY 1,2
"

bq query --use_legacy_sql=false \
"
#standardSQL
SELECT
COUNT(hits_product_v2ProductName) as number_of_products,
hits_product_v2ProductCategory
FROM \`data-to-insights.ecommerce.rev_transactions\`
WHERE hits_product_v2ProductName IS NOT NULL
GROUP BY hits_product_v2ProductCategory
ORDER BY number_of_products DESC
"

bq query --use_legacy_sql=false \
"
#standardSQL
SELECT
COUNT(DISTINCT hits_product_v2ProductName) as number_of_products,
hits_product_v2ProductCategory
FROM \`data-to-insights.ecommerce.rev_transactions\`
WHERE hits_product_v2ProductName IS NOT NULL
GROUP BY hits_product_v2ProductCategory
ORDER BY number_of_products DESC
LIMIT 5
"

echo "${BG_RED}${BOLD}Congratulations For Completing The Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#
