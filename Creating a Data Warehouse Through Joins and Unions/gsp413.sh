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

echo "${YELLOW}${BOLD}Starting${RESET}" "${GREEN}${BOLD}Execution${RESET}"

export PROJECT_ID=$(gcloud info --format='value(config.project)')

bq mk ecommerce

bq query --use_legacy_sql=false "
SELECT
  SKU,
  name,
  sentimentScore,
  sentimentMagnitude
FROM
  \`data-to-insights.ecommerce.products\`
ORDER BY
  sentimentScore DESC
LIMIT 5
"

bq query --use_legacy_sql=false "
SELECT
  SKU,
  name,
  sentimentScore,
  sentimentMagnitude
FROM
  \`data-to-insights.ecommerce.products\`
WHERE sentimentScore IS NOT NULL
ORDER BY
  sentimentScore
LIMIT 5
"

bq query --use_legacy_sql=false "
CREATE OR REPLACE TABLE ecommerce.sales_by_sku_20170801 AS
SELECT
  productSKU,
  SUM(IFNULL(productQuantity,0)) AS total_ordered
FROM
  \`data-to-insights.ecommerce.all_sessions_raw\`
WHERE date = '20170801'
GROUP BY productSKU
ORDER BY total_ordered DESC #462 skus sold
"


bq query --use_legacy_sql=false "
SELECT DISTINCT
  website.productSKU,
  website.total_ordered,
  inventory.name,
  inventory.stockLevel,
  inventory.restockingLeadTime,
  inventory.sentimentScore,
  inventory.sentimentMagnitude
FROM
  ecommerce.sales_by_sku_20170801 AS website
  LEFT JOIN \`data-to-insights.ecommerce.products\` AS inventory
  ON website.productSKU = inventory.SKU
ORDER BY total_ordered DESC
"

bq query --use_legacy_sql=false "
SELECT DISTINCT
  website.productSKU,
  website.total_ordered,
  inventory.name,
  inventory.stockLevel,
  inventory.restockingLeadTime,
  inventory.sentimentScore,
  inventory.sentimentMagnitude,
  SAFE_DIVIDE(website.total_ordered, inventory.stockLevel) AS ratio
FROM
  ecommerce.sales_by_sku_20170801 AS website
  LEFT JOIN \`data-to-insights.ecommerce.products\` AS inventory
  ON website.productSKU = inventory.SKU
# gone through more than 50% of inventory for the month
WHERE SAFE_DIVIDE(website.total_ordered,inventory.stockLevel) >= .50
ORDER BY total_ordered DESC
"

bq query --use_legacy_sql=false "
CREATE OR REPLACE TABLE ecommerce.sales_by_sku_20170802
(
productSKU STRING,
total_ordered INT64
);
"

bq query --use_legacy_sql=false "
INSERT INTO ecommerce.sales_by_sku_20170802
(productSKU, total_ordered)
VALUES('GGOEGHPA002910', 101)
"

bq query --use_legacy_sql=false "
SELECT * FROM ecommerce.sales_by_sku_20170801
UNION ALL
SELECT * FROM ecommerce.sales_by_sku_20170802
"

bq query --use_legacy_sql=false "
SELECT * FROM \`ecommerce.sales_by_sku_2017*\`
"

bq query --use_legacy_sql=false "
SELECT * FROM \`ecommerce.sales_by_sku_2017*\`
WHERE _TABLE_SUFFIX = '0802'
"

echo "${RED}${BOLD}Congratulations${RESET}" "${WHITE}${BOLD}for${RESET}" "${GREEN}${BOLD}Completing the Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#