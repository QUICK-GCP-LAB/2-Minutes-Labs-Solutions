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

bq mk bq_logs

bq query --use_legacy_sql=false "SELECT current_date()"

gcloud logging sinks create JobComplete bigquery.googleapis.com/projects/$DEVSHELL_PROJECT_ID/datasets/bq_logs --log-filter='resource.type="bigquery_resource"
protoPayload.methodName="jobservice.jobcompleted"'

bq query --location=us --use_legacy_sql=false --use_cache=false \
'SELECT fullName, AVG(CL.numberOfYears) avgyears
 FROM `qwiklabs-resources.qlbqsamples.persons_living`, UNNEST(citiesLived) as CL
 GROUP BY fullName'

bq query --location=us --use_legacy_sql=false --use_cache=false \
'select month, avg(mean_temp) as avgtemp from `qwiklabs-resources.qlweather_geo.gsod`
 where station_number = 947680
 and year = 2010
 group by month
 order by month'

bq query --location=us --use_legacy_sql=false --use_cache=false \
'select CONCAT(departure_airport, "-", arrival_airport) as route, count(*) as numberflights
 from `bigquery-samples.airline_ontime_data.airline_id_codes` ac,
 `qwiklabs-resources.qlairline_ontime_data.flights` fl
 where ac.code = fl.airline_code
 and regexp_contains(ac.airline ,  r"Alaska")
 group by 1
 order by 2 desc
 LIMIT 10'

sleep 360

bq query --location=us --use_legacy_sql=false --use_cache=false \
'SELECT fullName, AVG(CL.numberOfYears) avgyears
 FROM `qwiklabs-resources.qlbqsamples.persons_living`, UNNEST(citiesLived) as CL
 GROUP BY fullName'

bq query --location=us --use_legacy_sql=false --use_cache=false \
'select month, avg(mean_temp) as avgtemp from `qwiklabs-resources.qlweather_geo.gsod`
 where station_number = 947680
 and year = 2010
 group by month
 order by month'

bq query --location=us --use_legacy_sql=false --use_cache=false \
'select CONCAT(departure_airport, "-", arrival_airport) as route, count(*) as numberflights
 from `bigquery-samples.airline_ontime_data.airline_id_codes` ac,
 `qwiklabs-resources.qlairline_ontime_data.flights` fl
 where ac.code = fl.airline_code
 and regexp_contains(ac.airline ,  r"Alaska")
 group by 1
 order by 2 desc
 LIMIT 10'

#!/bin/bash

# Set your project ID
export PROJECT_ID="$DEVSHELL_PROJECT_ID"

# Define the command
COMMAND='bq query --use_legacy_sql=false "CREATE OR REPLACE VIEW \`$DEVSHELL_PROJECT_ID.bq_logs.v_querylogs\` AS SELECT resource.labels.project_id, protopayload_auditlog.authenticationInfo.principalEmail, protopayload_auditlog.servicedata_v1_bigquery.jobCompletedEvent.job.jobConfiguration.query.query, protopayload_auditlog.servicedata_v1_bigquery.jobCompletedEvent.job.jobConfiguration.query.statementType, protopayload_auditlog.servicedata_v1_bigquery.jobCompletedEvent.job.jobStatus.error.message, protopayload_auditlog.servicedata_v1_bigquery.jobCompletedEvent.job.jobStatistics.startTime, protopayload_auditlog.servicedata_v1_bigquery.jobCompletedEvent.job.jobStatistics.endTime, TIMESTAMP_DIFF(protopayload_auditlog.servicedata_v1_bigquery.jobCompletedEvent.job.jobStatistics.endTime, protopayload_auditlog.servicedata_v1_bigquery.jobCompletedEvent.job.jobStatistics.startTime, MILLISECOND)/1000 AS run_seconds, protopayload_auditlog.servicedata_v1_bigquery.jobCompletedEvent.job.jobStatistics.totalProcessedBytes, protopayload_auditlog.servicedata_v1_bigquery.jobCompletedEvent.job.jobStatistics.totalSlotMs, ARRAY(SELECT as STRUCT datasetid, tableId FROM UNNEST(protopayload_auditlog.servicedata_v1_bigquery.jobCompletedEvent.job.jobStatistics.referencedTables)) as tables_ref, protopayload_auditlog.servicedata_v1_bigquery.jobCompletedEvent.job.jobStatistics.totalTablesProcessed, protopayload_auditlog.servicedata_v1_bigquery.jobCompletedEvent.job.jobStatistics.queryOutputRowCount, severity FROM \`$DEVSHELL_PROJECT_ID.bq_logs.cloudaudit_googleapis_com_data_access_*\` ORDER BY startTime;"'

# Run the command until it succeeds
until eval "$COMMAND"
do
    echo "Command failed, retrying..."
    sleep 1 # Add a delay before retrying
done

echo "${BG_RED}${BOLD}Congratulations For Completing The Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#