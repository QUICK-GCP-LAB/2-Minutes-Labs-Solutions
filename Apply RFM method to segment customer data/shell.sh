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

bq query --use_legacy_sql=false \
'SELECT
  user_id AS customer_id,
  DATE_DIFF(CURRENT_TIMESTAMP(), MAX(created_at), DAY) AS recency
FROM `thelook_ecommerce.orders`
GROUP BY
  user_id
ORDER BY recency DESC
LIMIT 10;'

bq query --use_legacy_sql=false \
'SELECT
  user_id AS customer_id,
  COUNT(order_id) AS frequency
FROM `thelook_ecommerce.orders`
WHERE created_at >= "2022-01-01" AND created_at < "2023-01-01"
GROUP BY customer_id
ORDER BY frequency DESC
LIMIT 10;'

bq query --use_legacy_sql=false \
"
SELECT
 user_id AS customer_id,
 COUNT(order_id) as frequency,
FROM \`thelook_ecommerce.orders\`
WHERE created_at >= '2022-01-01' and created_at < '2023-01-01'
GROUP BY customer_id
ORDER BY frequency DESC
LIMIT 10;
"

bq query --use_legacy_sql=false \
"
SELECT
  o.user_id AS customer_id,
  SUM(oi.sale_price) as monetary
FROM \`thelook_ecommerce.orders\` o
INNER JOIN \`thelook_ecommerce.order_items\` oi
ON o.order_id = oi.order_id
WHERE o.created_at >= '2022-01-01' and o.created_at < '2023-01-01'
GROUP BY customer_id
LIMIT 10;
"

bq query --use_legacy_sql=false \
"
WITH
rfm_calc AS (
SELECT
o.user_id AS customer_id,
DATE_DIFF(CURRENT_TIMESTAMP(), MAX(o.created_at), DAY) AS recency,
COUNT(o.order_id) AS frequency,
ROUND(SUM(oi.sale_price)) AS monetary
FROM
\`thelook_ecommerce.orders\` o
INNER JOIN
\`thelook_ecommerce.order_items\` oi
ON
o.order_id = oi.order_id
GROUP BY
customer_id )

-- You'll now return values from this CTE
SELECT *
FROM
Rfm_calc;
"

bq query --use_legacy_sql=false \
"
WITH
rfm_calc AS (
SELECT
o.user_id AS customer_id,
DATE_DIFF(CURRENT_TIMESTAMP(), MAX(o.created_at), DAY) AS recency,
COUNT(o.order_id) AS frequency,
ROUND(SUM(oi.sale_price)) AS monetary
FROM
\`thelook_ecommerce.orders\` o
INNER JOIN
\`thelook_ecommerce.order_items\` oi
ON
o.order_id = oi.order_id
GROUP BY
customer_id ),

-- Here you're leveraging the rfm_calc CTE and creating another CTE
rfm_quant AS (
SELECT
customer_id,
NTILE(4) OVER (ORDER BY recency) AS recency_quantile,
NTILE(4) OVER (ORDER BY frequency) AS frequency_quantile,
NTILE(4) OVER (ORDER BY monetary) AS monetary_quantile
FROM
rfm_calc )

--And then you perform a select query that assigns categories based on quantile logic and returns values
SELECT
customer_id,recency_quantile, frequency_quantile, monetary_quantile,
CASE
WHEN monetary_quantile >= 3 AND frequency_quantile >= 3 THEN 'High Value Customer'
WHEN frequency_quantile >= 3 THEN 'Loyal Customer'
WHEN recency_quantile <= 1 THEN 'At Risk Customer'
WHEN recency_quantile >= 3 THEN 'Persuadable Customer'
END
AS customer_segment
FROM
rfm_quant;
"

echo "${BG_RED}${BOLD}Congratulations For Completing The Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#