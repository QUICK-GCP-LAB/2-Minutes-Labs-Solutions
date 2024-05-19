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

bq mk ecommerce

bq query \
--use_legacy_sql=false \
"
#standardSQL
# how many products are on the website?
SELECT DISTINCT
productSKU,
v2ProductName
FROM \`data-to-insights.ecommerce.all_sessions_raw\`;

#standardSQL
# find the count of unique SKUs
SELECT
DISTINCT
productSKU
FROM \`data-to-insights.ecommerce.all_sessions_raw\`;

SELECT
  v2ProductName,
  COUNT(DISTINCT productSKU) AS SKU_count,
  STRING_AGG(DISTINCT productSKU LIMIT 5) AS SKU
FROM \`data-to-insights.ecommerce.all_sessions_raw\`
  WHERE productSKU IS NOT NULL
  GROUP BY v2ProductName
  HAVING SKU_count > 1
  ORDER BY SKU_count DESC;

SELECT
  productSKU,
  COUNT(DISTINCT v2ProductName) AS product_count,
  STRING_AGG(DISTINCT v2ProductName LIMIT 5) AS product_name
FROM \`data-to-insights.ecommerce.all_sessions_raw\`
  WHERE v2ProductName IS NOT NULL
  GROUP BY productSKU
  HAVING product_count > 1
  ORDER BY product_count DESC;

SELECT DISTINCT
  v2ProductName,
  productSKU
FROM \`data-to-insights.ecommerce.all_sessions_raw\`
WHERE productSKU = 'GGOEGPJC019099';

SELECT
  SKU,
  name,
  stockLevel
FROM \`data-to-insights.ecommerce.products\`
WHERE SKU = 'GGOEGPJC019099';

SELECT DISTINCT
  website.v2ProductName,
  website.productSKU,
  inventory.stockLevel
FROM \`data-to-insights.ecommerce.all_sessions_raw\` AS website
JOIN \`data-to-insights.ecommerce.products\` AS inventory
  ON website.productSKU = inventory.SKU
  WHERE productSKU = 'GGOEGPJC019099';

WITH inventory_per_sku AS (
  SELECT DISTINCT
    website.v2ProductName,
    website.productSKU,
    inventory.stockLevel
  FROM \`data-to-insights.ecommerce.all_sessions_raw\` AS website
  JOIN \`data-to-insights.ecommerce.products\` AS inventory
    ON website.productSKU = inventory.SKU
    WHERE productSKU = 'GGOEGPJC019099'
)

SELECT
  productSKU,
  SUM(stockLevel) AS total_inventory
FROM inventory_per_sku
GROUP BY productSKU;

SELECT
  productSKU,
  ARRAY_AGG(DISTINCT v2ProductName) AS push_all_names_into_array
FROM \`data-to-insights.ecommerce.all_sessions_raw\`
WHERE productSKU = 'GGOEGAAX0098'
GROUP BY productSKU;

SELECT
  productSKU,
  ARRAY_AGG(DISTINCT v2ProductName LIMIT 1) AS push_all_names_into_array
FROM \`data-to-insights.ecommerce.all_sessions_raw\`
WHERE productSKU = 'GGOEGAAX0098'
GROUP BY productSKU;

#standardSQL
SELECT DISTINCT
website.productSKU
FROM \`data-to-insights.ecommerce.all_sessions_raw\` AS website
JOIN \`data-to-insights.ecommerce.products\` AS inventory
ON website.productSKU = inventory.SKU;

#standardSQL
# pull ID fields from both tables
SELECT DISTINCT
website.productSKU AS website_SKU,
inventory.SKU AS inventory_SKU
FROM \`data-to-insights.ecommerce.all_sessions_raw\` AS website
JOIN \`data-to-insights.ecommerce.products\` AS inventory
ON website.productSKU = inventory.SKU;
# IDs are present in both tables, how can you dig deeper?

#standardSQL
# the secret is in the JOIN type
# pull ID fields from both tables
SELECT DISTINCT
website.productSKU AS website_SKU,
inventory.SKU AS inventory_SKU
FROM \`data-to-insights.ecommerce.all_sessions_raw\` AS website
LEFT JOIN \`data-to-insights.ecommerce.products\` AS inventory
ON website.productSKU = inventory.SKU;

#standardSQL
# find product SKUs in website table but not in product inventory table
SELECT DISTINCT
website.productSKU AS website_SKU,
inventory.SKU AS inventory_SKU
FROM \`data-to-insights.ecommerce.all_sessions_raw\` AS website
LEFT JOIN \`data-to-insights.ecommerce.products\` AS inventory
ON website.productSKU = inventory.SKU
WHERE inventory.SKU IS NULL;

#standardSQL
# you can even pick one and confirm
SELECT * FROM \`data-to-insights.ecommerce.products\`
WHERE SKU = 'GGOEGATJ060517';
# query returns zero results

#standardSQL
# reverse the join
# find records in website but not in inventory
SELECT DISTINCT
website.productSKU AS website_SKU,
inventory.SKU AS inventory_SKU
FROM \`data-to-insights.ecommerce.all_sessions_raw\` AS website
RIGHT JOIN \`data-to-insights.ecommerce.products\` AS inventory
ON website.productSKU = inventory.SKU
WHERE website.productSKU IS NULL;

#standardSQL
# what are these products?
# add more fields in the SELECT STATEMENT
SELECT DISTINCT
website.productSKU AS website_SKU,
inventory.*
FROM \`data-to-insights.ecommerce.all_sessions_raw\` AS website
RIGHT JOIN \`data-to-insights.ecommerce.products\` AS inventory
ON website.productSKU = inventory.SKU
WHERE website.productSKU IS NULL;

#standardSQL
SELECT DISTINCT
website.productSKU AS website_SKU,
inventory.SKU AS inventory_SKU
FROM \`data-to-insights.ecommerce.all_sessions_raw\` AS website
FULL JOIN \`data-to-insights.ecommerce.products\` AS inventory
ON website.productSKU = inventory.SKU
WHERE website.productSKU IS NULL OR inventory.SKU IS NULL;

#standardSQL
CREATE OR REPLACE TABLE ecommerce.site_wide_promotion AS
SELECT .05 AS discount;

SELECT DISTINCT
productSKU,
v2ProductCategory,
discount
FROM \`data-to-insights.ecommerce.all_sessions_raw\` AS website
CROSS JOIN ecommerce.site_wide_promotion
WHERE v2ProductCategory LIKE '%Clearance%';

#standardSQL
SELECT DISTINCT
productSKU,
v2ProductCategory,
discount
FROM \`data-to-insights.ecommerce.all_sessions_raw\` AS website
CROSS JOIN ecommerce.site_wide_promotion
WHERE v2ProductCategory LIKE '%Clearance%'
AND productSKU = 'GGOEGOLC013299';
"

echo "${RED}${BOLD}Congratulations${RESET}" "${WHITE}${BOLD}for${RESET}" "${GREEN}${BOLD}Completing the Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#