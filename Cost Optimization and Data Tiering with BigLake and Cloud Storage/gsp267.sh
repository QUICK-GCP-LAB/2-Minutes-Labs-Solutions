clear

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

# Array of color codes excluding black and white
TEXT_COLORS=($RED $GREEN $YELLOW $BLUE $MAGENTA $CYAN)
BG_COLORS=($BG_RED $BG_GREEN $BG_YELLOW $BG_BLUE $BG_MAGENTA $BG_CYAN)

# Pick random colors
RANDOM_TEXT_COLOR=${TEXT_COLORS[$RANDOM % ${#TEXT_COLORS[@]}]}
RANDOM_BG_COLOR=${BG_COLORS[$RANDOM % ${#BG_COLORS[@]}]}

#----------------------------------------------------start--------------------------------------------------#

echo "${RANDOM_BG_COLOR}${RANDOM_TEXT_COLOR}${BOLD}Starting Execution${RESET}"

# Step 2: Set GCP project ID and project number
echo "${BLUE}${BOLD}Setting GCP project environment variables...${RESET}"
export GCP_PROJECT_ID=$(gcloud config list core/project --format="value(core.project)")
export GCP_PROJECT_NUM=$(gcloud projects describe $GCP_PROJECT_ID --format="value(projectNumber)")

# Step 3: Set default region
echo "${MAGENTA}${BOLD}Fetching GCP default region...${RESET}"
export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")

# Step 4: Enable BigQuery connection API
echo "${YELLOW}${BOLD}Enabling BigQuery connection API...${RESET}"
gcloud services enable bigqueryconnection.googleapis.com

# Step 5: Create GCS bucket
echo "${GREEN}${BOLD}Creating Cloud Storage bucket...${RESET}"
gcloud storage buckets create gs://${GCP_PROJECT_ID}-cymbal-bq-opt-big-lake --project=${GCP_PROJECT_ID} --default-storage-class=COLDLINE --location=$REGION --uniform-bucket-level-access

# Step 6: Export BigQuery table to GCS
echo "${CYAN}${BOLD}Exporting BigQuery data to Cloud Storage...${RESET}"
bq query --use_legacy_sql=false <<EOF
EXPORT DATA
OPTIONS (
   uri = 'gs://${DEVSHELL_PROJECT_ID}-cymbal-bq-opt-big-lake/top_products_20220801*',
   format = 'CSV',
   overwrite = true,
   header = true,
   field_delimiter = ';'
)
AS
SELECT
  product_name,
  volume_of_product_purchased
FROM
  \`cymbal_bq_opt_3.top_products_20220801_bigquerystorage\`;
EOF

# Step 7: Create BigQuery connection
echo "${RED}${BOLD}Creating BigQuery external connection...${RESET}"
bq mk \
  --connection \
  --location=$REGION \
  --project_id=${GCP_PROJECT_ID} \
  --connection_type=CLOUD_RESOURCE \
  mybiglakegcsconnector

# Step 8: Show BigQuery connection details
echo "${BLUE}${BOLD}Showing BigQuery connection details...${RESET}"
bq show --connection ${GCP_PROJECT_NUM}.$REGION.mybiglakegcsconnector

# Step 9: Grant IAM permission to the connection service account
echo "${MAGENTA}${BOLD}Granting IAM permissions to the service account...${RESET}"
export CONNECTION_SA=$(bq show --format=json --connection ${GCP_PROJECT_NUM}.$REGION.mybiglakegcsconnector  | jq ".cloudResource" | jq ".serviceAccountId" |tr -d '"')

gsutil iam ch serviceAccount:${CONNECTION_SA}:objectViewer gs://${GCP_PROJECT_ID}-cymbal-bq-opt-big-lake

sleep 15

# Step 10: Create an external BigQuery table
echo "${YELLOW}${BOLD}Creating external BigQuery table...${RESET}"
bq query --use_legacy_sql=false <<EOF
CREATE EXTERNAL TABLE
\`cymbal_bq_opt_3.top_products_20220801_biglake\`
WITH CONNECTION \`${DEVSHELL_PROJECT_ID}.${REGION}.mybiglakegcsconnector\`
OPTIONS (
  format = "CSV",
  field_delimiter = ";",
  uris = ['gs://${DEVSHELL_PROJECT_ID}-cymbal-bq-opt-big-lake/top_products_20220801*']
);
EOF

# Step 11: Create partitioned table
echo "${GREEN}${BOLD}Creating partitioned table...${RESET}"
bq query --use_legacy_sql=false <<EOF
CREATE TABLE
  cymbal_bq_opt_3.orders_with_timestamps_bigquerystorage
PARTITION BY
  orderdate
OPTIONS (
  require_partition_filter = TRUE
) AS
SELECT
  DATE(order_ts) AS orderdate,
  *
FROM
  \`cymbal_bq_opt_1.orders_with_timestamps\`;
EOF

# Step 12: Query data by partitions
echo "${CYAN}${BOLD}Querying partitioned table by date...${RESET}"
bq query --use_legacy_sql=false <<EOF
SELECT
  orderdate,
  COUNT(*) AS record_count
FROM
  \`cymbal_bq_opt_3.orders_with_timestamps_bigquerystorage\`
WHERE
  orderdate IN ("2022-08-01", "2022-08-02", "2022-08-03", "2022-08-04")
GROUP BY
  orderdate;
EOF

bq query --use_legacy_sql=false <<EOF
SELECT
  table_name,
  partition_id,
  total_rows
FROM
  \`cymbal_bq_opt_3.INFORMATION_SCHEMA.PARTITIONS\`
WHERE
  partition_id IS NOT NULL
  AND table_name = "orders_with_timestamps_bigquerystorage"
ORDER BY
  partition_id ASC;
EOF

bq query --use_legacy_sql=false <<EOF
EXPORT DATA
OPTIONS (
  uri = 'gs://${DEVSHELL_PROJECT_ID}-cymbal-bq-opt-big-lake/orders/orderdate=2022-08-01/*',
  format = 'CSV',
  overwrite = TRUE,
  header = TRUE,
  field_delimiter = ';'
) AS (
  SELECT
    * EXCEPT (orderdate)
  FROM
    \`cymbal_bq_opt_3.orders_with_timestamps_bigquerystorage\`
  WHERE
    orderdate = "2022-08-01"
);
EOF

bq query --use_legacy_sql=false <<EOF
EXPORT DATA
OPTIONS (
  uri = 'gs://${DEVSHELL_PROJECT_ID}-cymbal-bq-opt-big-lake/orders/orderdate=2022-08-02/*',
  format = 'CSV',
  overwrite = TRUE,
  header = TRUE,
  field_delimiter = ';'
) AS (
  SELECT
    * EXCEPT (orderdate)
  FROM
    \`cymbal_bq_opt_3.orders_with_timestamps_bigquerystorage\`
  WHERE
    orderdate = "2022-08-02"
);
EOF

# Step 13: Remove specific partitions from BigQuery
echo "${RED}${BOLD}Removing partitions from BigQuery...${RESET}"
bq rm --force --table ${GCP_PROJECT_ID}:cymbal_bq_opt_3.orders_with_timestamps_bigquerystorage\$20220801

bq rm --force --table ${GCP_PROJECT_ID}:cymbal_bq_opt_3.orders_with_timestamps_bigquerystorage\$20220802

# Step 14: Create external table with partition columns
echo "${BLUE}${BOLD}Creating an external table with partition columns...${RESET}"
bq query --use_legacy_sql=false <<EOF
CREATE EXTERNAL TABLE
  \`cymbal_bq_opt_3.orders_with_timestamps_biglake\`
WITH PARTITION COLUMNS (orderdate DATE)
WITH CONNECTION \`${DEVSHELL_PROJECT_ID}.${REGION}.mybiglakegcsconnector\`
OPTIONS (
   format ="CSV",
   field_delimiter = ";",
   uris = ['gs://${DEVSHELL_PROJECT_ID}-cymbal-bq-opt-big-lake/orders*'],
   hive_partition_uri_prefix = "gs://${DEVSHELL_PROJECT_ID}-cymbal-bq-opt-big-lake/orders",
   require_hive_partition_filter = TRUE );
EOF

# Step 15: Create a view combining storage tables
echo "${MAGENTA}${BOLD}Creating a combined view of storage tables...${RESET}"
bq query --use_legacy_sql=false <<EOF
CREATE OR REPLACE VIEW
  \`cymbal_bq_opt_3.orders_by_day\` AS (
    SELECT
      orderdate,
      order_ts,
      days_since_prior_order,
      order_dow,
      order_hour_of_day,
      order_id,
      order_number,
      user_id
    FROM (
      SELECT
        orderdate,
        order_ts,
        days_since_prior_order,
        order_dow,
        order_hour_of_day,
        order_id,
        order_number,
        user_id
      FROM
        \`cymbal_bq_opt_3.orders_with_timestamps_bigquerystorage\`
    )
    UNION ALL
    (
      SELECT
        orderdate,
        order_ts,
        days_since_prior_order,
        order_dow,
        order_hour_of_day,
        order_id,
        order_number,
        user_id
      FROM
        \`cymbal_bq_opt_3.orders_with_timestamps_biglake\`
    )
);
EOF

bq query --use_legacy_sql=false <<EOF
SELECT
  orderdate,
  COUNT(*) AS record_count
FROM
  \`cymbal_bq_opt_3.orders_by_day\`
WHERE
  orderdate IN ("2022-08-01", "2022-08-02", "2022-08-03", "2022-08-04")
GROUP BY
  orderdate;
EOF

echo

# Function to display a random congratulatory message
function random_congrats() {
    MESSAGES=(
        "${GREEN}Congratulations For Completing The Lab! Keep up the great work!${RESET}"
        "${CYAN}Well done! Your hard work and effort have paid off!${RESET}"
        "${YELLOW}Amazing job! You’ve successfully completed the lab!${RESET}"
        "${BLUE}Outstanding! Your dedication has brought you success!${RESET}"
        "${MAGENTA}Great work! You’re one step closer to mastering this!${RESET}"
        "${RED}Fantastic effort! You’ve earned this achievement!${RESET}"
        "${CYAN}Congratulations! Your persistence has paid off brilliantly!${RESET}"
        "${GREEN}Bravo! You’ve completed the lab with flying colors!${RESET}"
        "${YELLOW}Excellent job! Your commitment is inspiring!${RESET}"
        "${BLUE}You did it! Keep striving for more successes like this!${RESET}"
        "${MAGENTA}Kudos! Your hard work has turned into a great accomplishment!${RESET}"
        "${RED}You’ve smashed it! Completing this lab shows your dedication!${RESET}"
        "${CYAN}Impressive work! You’re making great strides!${RESET}"
        "${GREEN}Well done! This is a big step towards mastering the topic!${RESET}"
        "${YELLOW}You nailed it! Every step you took led you to success!${RESET}"
        "${BLUE}Exceptional work! Keep this momentum going!${RESET}"
        "${MAGENTA}Fantastic! You’ve achieved something great today!${RESET}"
        "${RED}Incredible job! Your determination is truly inspiring!${RESET}"
        "${CYAN}Well deserved! Your effort has truly paid off!${RESET}"
        "${GREEN}You’ve got this! Every step was a success!${RESET}"
        "${YELLOW}Nice work! Your focus and effort are shining through!${RESET}"
        "${BLUE}Superb performance! You’re truly making progress!${RESET}"
        "${MAGENTA}Top-notch! Your skill and dedication are paying off!${RESET}"
        "${RED}Mission accomplished! This success is a reflection of your hard work!${RESET}"
        "${CYAN}You crushed it! Keep pushing towards your goals!${RESET}"
        "${GREEN}You did a great job! Stay motivated and keep learning!${RESET}"
        "${YELLOW}Well executed! You’ve made excellent progress today!${RESET}"
        "${BLUE}Remarkable! You’re on your way to becoming an expert!${RESET}"
        "${MAGENTA}Keep it up! Your persistence is showing impressive results!${RESET}"
        "${RED}This is just the beginning! Your hard work will take you far!${RESET}"
        "${CYAN}Terrific work! Your efforts are paying off in a big way!${RESET}"
        "${GREEN}You’ve made it! This achievement is a testament to your effort!${RESET}"
        "${YELLOW}Excellent execution! You’re well on your way to mastering the subject!${RESET}"
        "${BLUE}Wonderful job! Your hard work has definitely paid off!${RESET}"
        "${MAGENTA}You’re amazing! Keep up the awesome work!${RESET}"
        "${RED}What an achievement! Your perseverance is truly admirable!${RESET}"
        "${CYAN}Incredible effort! This is a huge milestone for you!${RESET}"
        "${GREEN}Awesome! You’ve done something incredible today!${RESET}"
        "${YELLOW}Great job! Keep up the excellent work and aim higher!${RESET}"
        "${BLUE}You’ve succeeded! Your dedication is your superpower!${RESET}"
        "${MAGENTA}Congratulations! Your hard work has brought great results!${RESET}"
        "${RED}Fantastic work! You’ve taken a huge leap forward today!${RESET}"
        "${CYAN}You’re on fire! Keep up the great work!${RESET}"
        "${GREEN}Well deserved! Your efforts have led to success!${RESET}"
        "${YELLOW}Incredible! You’ve achieved something special!${RESET}"
        "${BLUE}Outstanding performance! You’re truly excelling!${RESET}"
        "${MAGENTA}Terrific achievement! Keep building on this success!${RESET}"
        "${RED}Bravo! You’ve completed the lab with excellence!${RESET}"
        "${CYAN}Superb job! You’ve shown remarkable focus and effort!${RESET}"
        "${GREEN}Amazing work! You’re making impressive progress!${RESET}"
        "${YELLOW}You nailed it again! Your consistency is paying off!${RESET}"
        "${BLUE}Incredible dedication! Keep pushing forward!${RESET}"
        "${MAGENTA}Excellent work! Your success today is well earned!${RESET}"
        "${RED}You’ve made it! This is a well-deserved victory!${RESET}"
        "${CYAN}Wonderful job! Your passion and hard work are shining through!${RESET}"
        "${GREEN}You’ve done it! Keep up the hard work and success will follow!${RESET}"
        "${YELLOW}Great execution! You’re truly mastering this!${RESET}"
        "${BLUE}Impressive! This is just the beginning of your journey!${RESET}"
        "${MAGENTA}You’ve achieved something great today! Keep it up!${RESET}"
        "${RED}You’ve made remarkable progress! This is just the start!${RESET}"
    )

    RANDOM_INDEX=$((RANDOM % ${#MESSAGES[@]}))
    echo -e "${BOLD}${MESSAGES[$RANDOM_INDEX]}"
}

# Display a random congratulatory message
random_congrats

echo -e "\n"  # Adding one blank line

cd

remove_files() {
    # Loop through all files in the current directory
    for file in *; do
        # Check if the file name starts with "gsp", "arc", or "shell"
        if [[ "$file" == gsp* || "$file" == arc* || "$file" == shell* ]]; then
            # Check if it's a regular file (not a directory)
            if [[ -f "$file" ]]; then
                # Remove the file and echo the file name
                rm "$file"
                echo "File removed: $file"
            fi
        fi
    done
}

remove_files
