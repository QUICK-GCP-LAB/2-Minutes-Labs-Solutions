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

bq mk --dataset $DEVSHELL_PROJECT_ID:ecommerce

bq query --use_legacy_sql=false "
#standardSQL

# copy one day of ecommerce data to explore
CREATE OR REPLACE TABLE ecommerce.all_sessions_raw_20170801
#schema
(
  fullVisitorId STRING OPTIONS(description='Unique visitor ID'),
  channelGrouping STRING OPTIONS(description='Channel e.g. Direct, Organic, Referral...')
)
 OPTIONS(
   description='Raw data from analyst team into our dataset for 08/01/2017'
 ) AS
 SELECT fullVisitorId, city FROM \`data-to-insights.ecommerce.all_sessions_raw\`
 WHERE date = '20170801'  #56,989 records
;
"

bq query --use_legacy_sql=false "
#standardSQL

# copy one day of ecommerce data to explore
CREATE OR REPLACE TABLE ecommerce.all_sessions_raw_20170801
#schema
(
  fullVisitorId STRING NOT NULL OPTIONS(description='Unique visitor ID'),
  channelGrouping STRING NOT NULL OPTIONS(description='Channel e.g. Direct, Organic, Referral...'),
  totalTransactionRevenue INT64 OPTIONS(description='Revenue * 10^6 for the transaction')
)
 OPTIONS(
   description='Raw data from analyst team into our dataset for 08/01/2017'
 ) AS
 SELECT fullVisitorId, channelGrouping, totalTransactionRevenue FROM \`data-to-insights.ecommerce.all_sessions_raw\`
 WHERE date = '20170801'  #56,989 records
;
"

bq query --use_legacy_sql=false "
#standardSQL

# copy one day of ecommerce data to explore
CREATE OR REPLACE TABLE ecommerce.revenue_transactions_20170801
#schema
(
  fullVisitorId STRING NOT NULL OPTIONS(description='Unique visitor ID'),
  visitId STRING NOT NULL OPTIONS(description='ID of the session, not unique across all users'),
  channelGrouping STRING NOT NULL OPTIONS(description='Channel e.g. Direct, Organic, Referral...'),
  totalTransactionRevenue FLOAT64 NOT NULL OPTIONS(description='Revenue for the transaction')
)
 OPTIONS(
   description='Revenue transactions for 08/01/2017'
 ) AS
 SELECT DISTINCT
  fullVisitorId,
  CAST(visitId AS STRING) AS visitId,
  channelGrouping,
  totalTransactionRevenue / 1000000 AS totalTransactionRevenue
 FROM \`data-to-insights.ecommerce.all_sessions_raw\`
 WHERE date = '20170801'
      AND totalTransactionRevenue IS NOT NULL #XX transactions
;
"

bq query --use_legacy_sql=false "
CREATE OR REPLACE TABLE ecommerce.all_sessions_raw_20170801
#schema
(
  fullVisitorId STRING NOT NULL OPTIONS(description='Unique visitor ID'),
  channelGrouping STRING NOT NULL OPTIONS(description='Channel e.g. Direct, Organic, Referral...'),
  totalTransactionRevenue INT64 NOT NULL OPTIONS(description='Revenue * 10^6 for the transaction')
)
 OPTIONS(
   description='Raw data from analyst team into our dataset for 08/01/2017'
 ) AS
 SELECT fullVisitorId, channelGrouping, totalTransactionRevenue FROM \`data-to-insights.ecommerce.all_sessions_raw\`
 WHERE date = '20170801'
"

bq query --use_legacy_sql=false "
CREATE OR REPLACE TABLE ecommerce.all_sessions_raw_20170801
#schema
(
  fullVisitorId STRING NOT NULL OPTIONS(description='Unique visitor ID'),
  channelGrouping STRING NOT NULL OPTIONS(description='Channel e.g. Direct, Organic, Referral...'),
  totalTransactionRevenue INT64 OPTIONS(description='Revenue * 10^6 for the transaction')
)
 OPTIONS(
   description='Raw data from analyst team into our dataset for 08/01/2017'
 ) AS
 SELECT fullVisitorId, channelGrouping, totalTransactionRevenue FROM \`data-to-insights.ecommerce.all_sessions_raw\`
 WHERE date = '20170801'
"

bq query --use_legacy_sql=false "
CREATE OR REPLACE TABLE ecommerce.revenue_transactions_20170801
#schema
(
  fullVisitorId STRING NOT NULL OPTIONS(description='Unique visitor ID'),
  visitId STRING NOT NULL OPTIONS(description='ID of the session, not unique across all users'),
  channelGrouping STRING NOT NULL OPTIONS(description='Channel e.g. Direct, Organic, Referral...'),
  totalTransactionRevenue FLOAT64 NOT NULL OPTIONS(description='Revenue for the transaction')
)
 OPTIONS(
   description='Revenue transactions for 08/01/2017'
 ) AS
 SELECT DISTINCT
  fullVisitorId,
  CAST(visitId AS STRING) AS visitId,
  channelGrouping,
  totalTransactionRevenue / 1000000 AS totalTransactionRevenue
 FROM \`data-to-insights.ecommerce.all_sessions_raw\`
 WHERE date = '20170801'
      AND totalTransactionRevenue IS NOT NULL
"

bq query --use_legacy_sql=false "
SELECT DISTINCT
  date,
  fullVisitorId,
  CAST(visitId AS STRING) AS visitId,
  channelGrouping,
  totalTransactionRevenue / 1000000 AS totalTransactionRevenue
 FROM \`data-to-insights.ecommerce.all_sessions_raw\`
 WHERE totalTransactionRevenue IS NOT NULL
 ORDER BY date DESC
 LIMIT 100
"

bq query --use_legacy_sql=false "
CREATE OR REPLACE VIEW ecommerce.vw_latest_transactions
AS
SELECT DISTINCT
  date,
  fullVisitorId,
  CAST(visitId AS STRING) AS visitId,
  channelGrouping,
  totalTransactionRevenue / 1000000 AS totalTransactionRevenue
 FROM \`data-to-insights.ecommerce.all_sessions_raw\`
 WHERE totalTransactionRevenue IS NOT NULL
 ORDER BY date DESC
 LIMIT 100
"

bq query --use_legacy_sql=false "
CREATE OR REPLACE VIEW ecommerce.vw_latest_transactions
OPTIONS(
  description='latest 100 ecommerce transactions',
  labels=[('report_type','operational')]
)
AS
SELECT DISTINCT
  date,
  fullVisitorId,
  CAST(visitId AS STRING) AS visitId,
  channelGrouping,
  totalTransactionRevenue / 1000000 AS totalTransactionRevenue
 FROM \`data-to-insights.ecommerce.all_sessions_raw\`
 WHERE totalTransactionRevenue IS NOT NULL
 ORDER BY date DESC
 LIMIT 100
"

bq query --use_legacy_sql=false "
CREATE OR REPLACE VIEW ecommerce.vw_latest_transactions
OPTIONS(
  description='latest 50 ecommerce transactions',
  labels=[('report_type','operational')]
)
AS
SELECT DISTINCT
  date,
  fullVisitorId,
  CAST(visitId AS STRING) AS visitId,
  channelGrouping,
  totalTransactionRevenue / 1000000 AS totalTransactionRevenue
 FROM \`data-to-insights.ecommerce.all_sessions_raw\`
 WHERE totalTransactionRevenue IS NOT NULL
 ORDER BY date DESC
 LIMIT 50
"

bq query --use_legacy_sql=false "
CREATE OR REPLACE VIEW ecommerce.vw_latest_transactions
OPTIONS(
  description='latest 50 ecommerce transactions',
  labels=[('report_type','operational')]
)
AS
SELECT DISTINCT
  date,
  fullVisitorId,
  CAST(visitId AS STRING) AS visitId,
  channelGrouping,
  totalTransactionRevenue / 1000000 AS totalTransactionRevenue
 FROM \`data-to-insights.ecommerce.all_sessions_raw\`
 WHERE totalTransactionRevenue IS NOT NULL
 ORDER BY date DESC
 LIMIT 50
"

bq query --use_legacy_sql=false "
#standardSQL
CREATE OR REPLACE VIEW ecommerce.vw_large_transactions
OPTIONS(
  description='large transactions for review',
  labels=[('org_unit','loss_prevention')]
)
AS
SELECT DISTINCT
  date,
  fullVisitorId,
  visitId,
  channelGrouping,
  totalTransactionRevenue / 1000000 AS revenue,
  currencyCode
  #v2ProductName
 FROM \`data-to-insights.ecommerce.all_sessions_raw\`
 WHERE
  (totalTransactionRevenue / 1000000) > 1000
  AND currencyCode = 'USD'
 ORDER BY date DESC # latest transactions
 LIMIT 10
;
"

bq query --use_legacy_sql=false "
CREATE OR REPLACE VIEW ecommerce.vw_large_transactions
OPTIONS(
  description='large transactions for review',
  labels=[('org_unit','loss_prevention')]
)
AS
SELECT DISTINCT
  date,
  fullVisitorId,
  visitId,
  channelGrouping,
  totalTransactionRevenue / 1000000 AS totalTransactionRevenue,
  currencyCode,
  STRING_AGG(DISTINCT v2ProductName ORDER BY v2ProductName LIMIT 10) AS products_ordered
 FROM \`data-to-insights.ecommerce.all_sessions_raw\`
 WHERE
  (totalTransactionRevenue / 1000000) > 1000
  AND currencyCode = 'USD'
 GROUP BY 1,2,3,4,5,6
 ORDER BY date DESC
 LIMIT 10
"

bq query --use_legacy_sql=false "
SELECT DISTINCT
  SESSION_USER() AS viewer_ldap,
  REGEXP_EXTRACT(SESSION_USER(), r'@(.+)') AS domain,
  date,
  fullVisitorId,
  visitId,
  channelGrouping,
  totalTransactionRevenue / 1000000 AS totalTransactionRevenue,
  currencyCode,
  STRING_AGG(DISTINCT v2ProductName ORDER BY v2ProductName LIMIT 10) AS products_ordered
 FROM \`data-to-insights.ecommerce.all_sessions_raw\`
 WHERE
  (totalTransactionRevenue / 1000000) > 1000
  AND currencyCode = 'USD'
  AND REGEXP_EXTRACT(SESSION_USER(), r'@(.+)') IN ('qwiklabs.net')
 GROUP BY 1,2,3,4,5,6,7,8
 ORDER BY date DESC
 LIMIT 10
"

bq query --use_legacy_sql=false "
CREATE OR REPLACE VIEW ecommerce.vw_large_transactions
OPTIONS(
  description='large transactions for review',
  labels=[('org_unit','loss_prevention')],
  expiration_timestamp=TIMESTAMP_ADD(CURRENT_TIMESTAMP(), INTERVAL 90 DAY)
)
AS
SELECT DISTINCT
  SESSION_USER() AS viewer_ldap,
  REGEXP_EXTRACT(SESSION_USER(), r'@(.+)') AS domain,
  date,
  fullVisitorId,
  visitId,
  channelGrouping,
  totalTransactionRevenue / 1000000 AS totalTransactionRevenue,
  currencyCode,
  STRING_AGG(DISTINCT v2ProductName ORDER BY v2ProductName LIMIT 10) AS products_ordered
 FROM \`data-to-insights.ecommerce.all_sessions_raw\`
 WHERE
  (totalTransactionRevenue / 1000000) > 1000
  AND currencyCode = 'USD'
  AND REGEXP_EXTRACT(SESSION_USER(), r'@(.+)') IN ('qwiklabs.net')

 GROUP BY 1,2,3,4,5,6,7,8
  ORDER BY date DESC
  LIMIT 10
"

echo "${RED}${BOLD}Congratulations${RESET}" "${WHITE}${BOLD}for${RESET}" "${GREEN}${BOLD}Completing the Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#