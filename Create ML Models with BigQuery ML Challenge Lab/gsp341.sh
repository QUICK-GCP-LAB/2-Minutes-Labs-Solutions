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

bq mk austin

bq --location=US mk --dataset bq_dataset

export EVALUATION_YEAR=2019

bq query --use_legacy_sql=false "
CREATE OR REPLACE MODEL austin.austin_location_model
OPTIONS (
  model_type='linear_reg',
  labels=['duration_minutes']
) AS
SELECT
  start_station_name,
  EXTRACT(HOUR FROM start_time) AS start_hour,
  EXTRACT(DAYOFWEEK FROM start_time) AS day_of_week,
  duration_minutes,
  address AS location
FROM
  \`bigquery-public-data.austin_bikeshare.bikeshare_trips\` AS trips
JOIN
  \`bigquery-public-data.austin_bikeshare.bikeshare_stations\` AS stations
ON
  trips.start_station_name = stations.name
WHERE
  EXTRACT(YEAR FROM start_time) = $EVALUATION_YEAR
  AND duration_minutes > 0;
"

bq query --use_legacy_sql=false "
SELECT
  SQRT(mean_squared_error) AS rmse,
  mean_absolute_error
FROM
  ML.EVALUATE(MODEL austin.austin_location_model, (
  SELECT
    start_station_name,
    EXTRACT(HOUR FROM start_time) AS start_hour,
    EXTRACT(DAYOFWEEK FROM start_time) AS day_of_week,
    duration_minutes,
    address AS location
  FROM
    \`bigquery-public-data.austin_bikeshare.bikeshare_trips\` AS trips
  JOIN
    \`bigquery-public-data.austin_bikeshare.bikeshare_stations\` AS stations
  ON
    trips.start_station_name = stations.name
  WHERE EXTRACT(YEAR FROM start_time) = $EVALUATION_YEAR)
)"


bq query --use_legacy_sql=false "
SELECT
  SQRT(mean_squared_error) AS rmse,
  mean_absolute_error
FROM
  ML.EVALUATE(MODEL austin.location_model, (
  SELECT
    start_station_name,
    EXTRACT(HOUR FROM start_time) AS start_hour,
    EXTRACT(DAYOFWEEK FROM start_time) AS day_of_week,
    duration_minutes,
	 address as location
  FROM
    \`bigquery-public-data.austin_bikeshare.bikeshare_trips\` AS trips
  JOIN
   \`bigquery-public-data.austin_bikeshare.bikeshare_stations\` AS stations
  ON
    trips.start_station_name = stations.name
  WHERE EXTRACT(YEAR FROM start_time) = $EVALUATION_YEAR)
)"


bq query --use_legacy_sql=false "
SELECT
  SQRT(mean_squared_error) AS rmse,
  mean_absolute_error
FROM
  ML.EVALUATE(MODEL austin.subscriber_model, (
  SELECT
    start_station_name,
    EXTRACT(HOUR FROM start_time) AS start_hour,
    subscriber_type,
    duration_minutes
  FROM
    \`bigquery-public-data.austin_bikeshare.bikeshare_trips\` AS trips
  WHERE
    EXTRACT(YEAR FROM start_time) = $EVALUATION_YEAR)
)"


bq query --use_legacy_sql=false "
SELECT
  start_station_name,
  COUNT(*) AS trips
FROM
  \`bigquery-public-data.austin_bikeshare.bikeshare_trips\`
WHERE
  EXTRACT(YEAR FROM start_time) = $EVALUATION_YEAR
GROUP BY
  start_station_name
ORDER BY
  trips DESC
"

bq query --use_legacy_sql=false "
SELECT AVG(predicted_duration_minutes) AS average_predicted_trip_length
FROM ML.predict(MODEL austin.subscriber_model, (
SELECT
    start_station_name,
    EXTRACT(HOUR FROM start_time) AS start_hour,
    subscriber_type,
    duration_minutes
FROM
  \`bigquery-public-data.austin_bikeshare.bikeshare_trips\`
WHERE
  EXTRACT(YEAR FROM start_time) = $EVALUATION_YEAR
  AND subscriber_type = 'Single Trip'
  AND start_station_name = '21st & Speedway @PCL'))"

bq query --use_legacy_sql=false \
"
CREATE OR REPLACE MODEL \`ecommerce.customer_classification_model\`
OPTIONS
(
model_type='logistic_reg',
labels = ['will_buy_on_return_visit']
)
AS
#standardSQL
SELECT
* EXCEPT(fullVisitorId)
FROM
# features
(SELECT
fullVisitorId,
IFNULL(totals.bounces, 0) AS bounces,
IFNULL(totals.timeOnSite, 0) AS time_on_site
FROM
\`data-to-insights.ecommerce.web_analytics\`
WHERE
totals.newVisits = 1
AND date BETWEEN '20160801' AND '20170430') # train on first 9 months
JOIN
(SELECT
fullvisitorid,
IF(COUNTIF(totals.transactions > 0 AND totals.newVisits IS NULL) > 0, 1, 0) AS will_buy_on_return_visit
FROM
\`data-to-insights.ecommerce.web_analytics\`
GROUP BY fullvisitorid)
USING (fullVisitorId)
;
"

bq query --use_legacy_sql=false \
"
#standardSQL
CREATE OR REPLACE MODEL \`ecommerce.customer_classification_model\`
OPTIONS(model_type='logistic_reg') AS
SELECT
  IF(totals.transactions IS NULL, 0, 1) AS label,
  IFNULL(device.operatingSystem, '') AS os,
  device.isMobile AS is_mobile,
  IFNULL(geoNetwork.country, '') AS country,
  IFNULL(totals.pageviews, 0) AS pageviews
FROM
  \`bigquery-public-data.google_analytics_sample.ga_sessions_*\`
WHERE
  _TABLE_SUFFIX BETWEEN '20160801' AND '20170631'
LIMIT 100000;
"

bq query --use_legacy_sql=false \
"
#standardSQL
SELECT
  *
FROM
  ml.EVALUATE(MODEL \`ecommerce.customer_classification_model\`, (
SELECT
  IF(totals.transactions IS NULL, 0, 1) AS label,
  IFNULL(device.operatingSystem, '') AS os,
  device.isMobile AS is_mobile,
  IFNULL(geoNetwork.country, '') AS country,
  IFNULL(totals.pageviews, 0) AS pageviews
FROM
  \`bigquery-public-data.google_analytics_sample.ga_sessions_*\`
WHERE
  _TABLE_SUFFIX BETWEEN '20170701' AND '20170801'));
"

bq query --use_legacy_sql=false \
"
#standardSQL
SELECT
  country,
  SUM(predicted_label) as total_predicted_purchases
FROM
  ml.PREDICT(MODEL \`ecommerce.customer_classification_model\`, (
SELECT
  IFNULL(device.operatingSystem, '') AS os,
  device.isMobile AS is_mobile,
  IFNULL(totals.pageviews, 0) AS pageviews,
  IFNULL(geoNetwork.country, '') AS country
FROM
  \`bigquery-public-data.google_analytics_sample.ga_sessions_*\`
WHERE
  _TABLE_SUFFIX BETWEEN '20170701' AND '20170801'))
GROUP BY country
ORDER BY total_predicted_purchases DESC
LIMIT 10;
"

bq query --use_legacy_sql=false \
"
#standardSQL
SELECT
  fullVisitorId,
  SUM(predicted_label) as total_predicted_purchases
FROM
  ml.PREDICT(MODEL \`ecommerce.customer_classification_model\`, (
SELECT
  IFNULL(device.operatingSystem, '') AS os,
  device.isMobile AS is_mobile,
  IFNULL(totals.pageviews, 0) AS pageviews,
  IFNULL(geoNetwork.country, '') AS country,
  fullVisitorId
FROM
  \`bigquery-public-data.google_analytics_sample.ga_sessions_*\`
WHERE
  _TABLE_SUFFIX BETWEEN '20170701' AND '20170801'))
GROUP BY fullVisitorId
ORDER BY total_predicted_purchases DESC
LIMIT 10;
"

bq --location=US mk --dataset bq_dataset

bq query --use_legacy_sql=false "
CREATE OR REPLACE MODEL bqml_dataset.predicts_visitor_model
OPTIONS(model_type='logistic_reg') AS
SELECT
  IF(totals.transactions IS NULL, 0, 1) AS label,
  IFNULL(device.operatingSystem, '') AS os,
  device.isMobile AS is_mobile,
  IFNULL(geoNetwork.country, '') AS country,
  IFNULL(totals.pageviews, 0) AS pageviews
FROM
  \`bigquery-public-data.google_analytics_sample.ga_sessions_*\`
WHERE
  _TABLE_SUFFIX BETWEEN '20160801' AND '20170631'
  LIMIT 100000;
"

bq query --use_legacy_sql=false \
"
#standardSQL
SELECT
  *
FROM
  ml.EVALUATE(MODEL \`bqml_dataset.predicts_visitor_model\`, (
SELECT
  IF(totals.transactions IS NULL, 0, 1) AS label,
  IFNULL(device.operatingSystem, '') AS os,
  device.isMobile AS is_mobile,
  IFNULL(geoNetwork.country, '') AS country,
  IFNULL(totals.pageviews, 0) AS pageviews
FROM
  \`bigquery-public-data.google_analytics_sample.ga_sessions_*\`
WHERE
  _TABLE_SUFFIX BETWEEN '20170701' AND '20170801'));
"

bq query --use_legacy_sql=false \
"
#standardSQL
SELECT
  country,
  SUM(predicted_label) as total_predicted_purchases
FROM
  ml.PREDICT(MODEL \`bqml_dataset.predicts_visitor_model\`, (
SELECT
  IFNULL(device.operatingSystem, '') AS os,
  device.isMobile AS is_mobile,
  IFNULL(totals.pageviews, 0) AS pageviews,
  IFNULL(geoNetwork.country, '') AS country
FROM
  \`bigquery-public-data.google_analytics_sample.ga_sessions_*\`
WHERE
  _TABLE_SUFFIX BETWEEN '20170701' AND '20170801'))
GROUP BY country
ORDER BY total_predicted_purchases DESC
LIMIT 10;
"

bq query --use_legacy_sql=false \
"
#standardSQL
SELECT
  fullVisitorId,
  SUM(predicted_label) as total_predicted_purchases
FROM
  ml.PREDICT(MODEL \`bqml_dataset.predicts_visitor_model\`, (
SELECT
  IFNULL(device.operatingSystem, '') AS os,
  device.isMobile AS is_mobile,
  IFNULL(totals.pageviews, 0) AS pageviews,
  IFNULL(geoNetwork.country, '') AS country,
  fullVisitorId
FROM
  \`bigquery-public-data.google_analytics_sample.ga_sessions_*\`
WHERE
  _TABLE_SUFFIX BETWEEN '20170701' AND '20170801'))
GROUP BY fullVisitorId
ORDER BY total_predicted_purchases DESC
LIMIT 10;
"

echo "${BG_RED}${BOLD}Congratulations For Completing The Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#