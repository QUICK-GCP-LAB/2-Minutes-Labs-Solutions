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

# Step 1: Set project ID
echo "${GREEN}${BOLD}Setting project ID...${RESET}"
export PROJECT_ID=$(gcloud config get-value project)

# Step 2: Copy data file from Cloud Storage bucket
echo "${BLUE}${BOLD}Copying data file from Cloud Storage...${RESET}"
gsutil cp gs://spls/gsp774/archive.zip .

# Step 3: Extract the ZIP archive
echo "${MAGENTA}${BOLD}Extracting ZIP archive...${RESET}"
unzip archive.zip

# Step 4: Set data file variable
echo "${CYAN}${BOLD}Setting data file variable...${RESET}"
export DATA_FILE=PS_20174392719_1491204439457_log.csv

# Step 5: Create BigQuery dataset
echo "${RED}${BOLD}Creating BigQuery dataset 'finance'...${RESET}"
bq mk --dataset $PROJECT_ID:finance

# Step 6: Create a Cloud Storage bucket
echo "${YELLOW}${BOLD}Creating Cloud Storage bucket...${RESET}"
gsutil mb gs://$PROJECT_ID

# Step 7: Upload data file to Cloud Storage
echo "${GREEN}${BOLD}Uploading data file to Cloud Storage bucket...${RESET}"
gsutil cp $DATA_FILE gs://$PROJECT_ID

# Step 8: Load data into BigQuery
echo "${BLUE}${BOLD}Loading data into BigQuery table 'finance.fraud_data'...${RESET}"
bq load --autodetect --source_format=CSV --max_bad_records=100000 finance.fraud_data gs://$PROJECT_ID/$DATA_FILE

# Step 9: Query data summary by type and fraud status
echo "${MAGENTA}${BOLD}Querying data summary by transaction type and fraud status...${RESET}"
bq query --use_legacy_sql=false \
"SELECT type, isFraud, count(*) as cnt
 FROM \`finance.fraud_data\`
 GROUP BY isFraud, type
 ORDER BY type"

# Step 10: Query fraud count for specific transaction types
echo "${CYAN}${BOLD}Querying fraud count for 'CASH_OUT' and 'TRANSFER' transactions...${RESET}"
bq query --use_legacy_sql=false \
'SELECT isFraud, count(*) as cnt
FROM `finance.fraud_data`
WHERE type in ("CASH_OUT", "TRANSFER")
GROUP BY isFraud'

# Step 11: Query top 10 largest transactions
echo "${RED}${BOLD}Querying top 10 largest transactions by amount...${RESET}"
bq query --use_legacy_sql=false \
"SELECT *
 FROM \`finance.fraud_data\`
 ORDER BY amount DESC
 LIMIT 10"

# Step 12: Create a sample dataset with additional features
echo "${YELLOW}${BOLD}Creating a sampled dataset with additional features...${RESET}"
bq query --use_legacy_sql=false \
'CREATE OR REPLACE TABLE finance.fraud_data_sample AS
SELECT
      type,
      amount,
      nameOrig,
      nameDest,
      oldbalanceOrg as oldbalanceOrig,  #standardize the naming.
      newbalanceOrig,
      oldbalanceDest,
      newbalanceDest,
# add new features:
      if(oldbalanceOrg = 0.0, 1, 0) as origzeroFlag,
      if(newbalanceDest = 0.0, 1, 0) as destzeroFlag,
      round((newbalanceDest-oldbalanceDest-amount)) as amountError,
      generate_uuid() as id,        #create a unique id for each transaction.
      isFraud
FROM finance.fraud_data
WHERE
# filter unnecessary transaction types:
      type in("CASH_OUT","TRANSFER") AND
# undersample:
      (isFraud = 1 or (RAND()< 10/100))'  # select 10% of the non-fraud cases

# Step 13: Split data into test and model datasets
echo "${GREEN}${BOLD}Splitting data into test and model datasets...${RESET}"
bq query --use_legacy_sql=false \
"CREATE OR REPLACE TABLE finance.fraud_data_test AS
SELECT *
FROM finance.fraud_data_sample
where RAND() < 20/100"

bq query --use_legacy_sql=false \
"CREATE OR REPLACE TABLE finance.fraud_data_model AS
SELECT
*
FROM finance.fraud_data_sample  
EXCEPT distinct select * from finance.fraud_data_test"

# Step 14: Train an unsupervised model
echo "${BLUE}${BOLD}Training an unsupervised model using K-Means clustering...${RESET}"
bq query --use_legacy_sql=false \
"CREATE OR REPLACE MODEL
  finance.model_unsupervised OPTIONS(model_type='kmeans', num_clusters=5) AS
SELECT
  amount, oldbalanceOrig, newbalanceOrig, oldbalanceDest, newbalanceDest, type, origzeroFlag, destzeroFlag, amountError
  FROM
  \`finance.fraud_data_model\`"

# Step 15: Analyzing fraud distribution across centroids
echo "${MAGENTA}${BOLD}Analyzing fraud distribution across centroids...${RESET}"
bq query --use_legacy_sql=false \
'SELECT
  centroid_id, sum(isfraud) as fraud_cnt,  count(*) total_cnt
FROM
  ML.PREDICT(MODEL `finance.model_unsupervised`,
    (
    SELECT *
    FROM  `finance.fraud_data_test`))
group by centroid_id
order by centroid_id'

# Step 16: Train a supervised model using logistic regression
echo "${GREEN}${BOLD}Training a supervised model using logistic regression...${RESET}"
bq query --use_legacy_sql=false \
"CREATE OR REPLACE MODEL
  finance.model_supervised_initial
  OPTIONS(model_type='LOGISTIC_REG', INPUT_LABEL_COLS = ['isfraud']
  )
AS
SELECT
type, amount, oldbalanceOrig, newbalanceOrig, oldbalanceDest, newbalanceDest, isFraud
FROM finance.fraud_data_model"

# Step 17: Retrieving model weights for supervised logistic regression model
echo "${CYAN}${BOLD}Retrieving model weights for supervised logistic regression model...${RESET}"
bq query --use_legacy_sql=false \
'SELECT
  *
FROM
  ML.WEIGHTS(MODEL `finance.model_supervised_initial`,
    STRUCT(true AS standardize))'

# Step 18: Predicting fraud cases using the supervised model
echo "${RED}${BOLD}Predicting fraud cases using the supervised model...${RESET}"
bq query --use_legacy_sql=false \
'SELECT id, label as predicted, isFraud as actual
FROM
  ML.PREDICT(MODEL `finance.model_supervised_initial`,
   (
    SELECT  *
    FROM  `finance.fraud_data_test`
   )
  ), unnest(predicted_isfraud_probs) as p
where p.label = 1 and p.prob > 0.5'

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