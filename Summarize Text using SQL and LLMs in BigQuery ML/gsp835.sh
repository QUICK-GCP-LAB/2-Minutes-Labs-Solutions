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

bq mk bq_llm

bq mk --connection --location=us --project_id=$DEVSHELL_PROJECT_ID \
    --connection_type=CLOUD_RESOURCE llm-connection

CONNECTION_NAME="$DEVSHELL_PROJECT_ID.us.llm-connection"
bq show --connection $CONNECTION_NAME > connection_details.json

SERVICE_ACCOUNT_ID=$(bq show --connection $CONNECTION_NAME | grep 'serviceAccountId' | awk -F\" '{print $4}')
export SERVICE_ACCOUNT_ID
echo "Service Account ID: $SERVICE_ACCOUNT_ID"

gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
  --member="serviceAccount:$SERVICE_ACCOUNT_ID" \
  --role="roles/aiplatform.user"

bq query --use_legacy_sql=false \
"
CREATE OR REPLACE MODEL bq_llm.llm_model
  REMOTE WITH CONNECTION \`us.llm-connection\`
  OPTIONS (remote_service_type = 'CLOUD_AI_LARGE_LANGUAGE_MODEL_V1');
"

sleep 60

bq query --use_legacy_sql=false \
"
SELECT
  ml_generate_text_result['predictions'][0]['content'] AS generated_text,
  ml_generate_text_result['predictions'][0]['safetyAttributes']
    AS safety_attributes,
  * EXCEPT (ml_generate_text_result)
FROM
  ML.GENERATE_TEXT(
    MODEL \`bq_llm.llm_model\`,
    (
  SELECT
        CONCAT('Can you read the code in the following text and generate a summary for what the code is doing and what language it is written in:', content)
        AS prompt from \`bigquery-public-data.github_repos.sample_contents\`
          limit 5
    ),
    STRUCT(
      0.2 AS temperature,
      100 AS max_output_tokens));
"

sleep 30

bq query --use_legacy_sql=false \
"
SELECT
  ml_generate_text_result['predictions'][0]['content'] AS generated_text,
  ml_generate_text_result['predictions'][0]['safetyAttributes']
    AS safety_attributes,
  * EXCEPT (ml_generate_text_result)
FROM
  ML.GENERATE_TEXT(
    MODEL \`bq_llm.llm_model\`,
    (
  SELECT
        CONCAT('Can you read the code in the following text and generate a summary for what the code is doing and what language it is written in:', content)
        AS prompt from \`bigquery-public-data.github_repos.sample_contents\`
          limit 5
    ),
    STRUCT(
      0.2 AS temperature,
      100 AS max_output_tokens));
"

sleep 30

bq query --use_legacy_sql=false \
"
SELECT
  ml_generate_text_result['predictions'][0]['content'] AS generated_text,
  ml_generate_text_result['predictions'][0]['safetyAttributes']
    AS safety_attributes,
  * EXCEPT (ml_generate_text_result)
FROM
  ML.GENERATE_TEXT(
    MODEL \`bq_llm.llm_model\`,
    (
  SELECT
        CONCAT('Can you read the code in the following text and generate a summary for what the code is doing and what language it is written in:', content)
        AS prompt from \`bigquery-public-data.github_repos.sample_contents\`
          limit 5
    ),
    STRUCT(
      0.2 AS temperature,
      100 AS max_output_tokens));
"

bq query --use_legacy_sql=false \
"
SELECT
  ml_generate_text_result['predictions'][0]['content'] AS generated_text,
  ml_generate_text_result['predictions'][0]['safetyAttributes']
    AS safety_attributes,
  * EXCEPT (ml_generate_text_result)
FROM
  ML.GENERATE_TEXT(
    MODEL \`bq_llm.llm_model\`,
    (
  SELECT
        CONCAT('Can you read the code in the following text and generate a summary for what the code is doing and what language it is written in:', content)
        AS prompt from \`bigquery-public-data.github_repos.sample_contents\`
          limit 5
    ),
    STRUCT(
      0.2 AS temperature,
      100 AS max_output_tokens));
"

echo "${RED}${BOLD}Congratulations${RESET}" "${WHITE}${BOLD}for${RESET}" "${GREEN}${BOLD}Completing the Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#