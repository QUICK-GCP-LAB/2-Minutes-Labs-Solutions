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

# Step 1: Create a Cloud Resource Connection
echo "${BLUE}${BOLD}Creating a Cloud Resource Connection${RESET}"
bq mk --connection --location=US --project_id=$DEVSHELL_PROJECT_ID --connection_type=CLOUD_RESOURCE gemini_conn

# Step 2: Exporting service account
echo "${GREEN}${BOLD}Exporting service account${RESET}"
export SERVICE_ACCOUNT=$(bq show --format=json --connection $DEVSHELL_PROJECT_ID.US.gemini_conn | jq -r '.cloudResource.serviceAccountId')

# Step 3: Adding IAM Policy Binding for AI Platform User
echo "${YELLOW}${BOLD}Adding IAM Policy Binding for AI Platform User${RESET}"
gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
    --member=serviceAccount:$SERVICE_ACCOUNT \
    --role="roles/aiplatform.user"

# Step 4: Adding IAM Policy Binding for Storage Object Admin
echo "${BLUE}${BOLD}Adding IAM Policy Binding for Storage Object Admin${RESET}"
gcloud storage buckets add-iam-policy-binding gs://$DEVSHELL_PROJECT_ID-bucket \
    --member="serviceAccount:$SERVICE_ACCOUNT" \
    --role="roles/storage.objectAdmin"

# Step 5: Creating BigQuery Dataset gemini_demo
echo "${MAGENTA}${BOLD}Creating BigQuery Dataset gemini_demo${RESET}"
bq --location=US mk gemini_demo

# Step 6: Loading customer reviews data from CSV
echo "${CYAN}${BOLD}Loading customer reviews data from CSV${RESET}"
bq query --use_legacy_sql=false \
"
LOAD DATA OVERWRITE gemini_demo.customer_reviews
(customer_review_id INT64, customer_id INT64, location_id INT64, review_datetime DATETIME, review_text STRING, social_media_source STRING, social_media_handle STRING)
FROM FILES (
  format = 'CSV',
  uris = ['gs://$DEVSHELL_PROJECT_ID-bucket/gsp1246/customer_reviews.csv']);
"

sleep 15

# Step 7: Creating or replacing external table for review images
echo "${GREEN}${BOLD}Creating or replacing external table for review images${RESET}"
bq query --use_legacy_sql=false \
"
CREATE OR REPLACE EXTERNAL TABLE
  \`gemini_demo.review_images\`
WITH CONNECTION \`us.gemini_conn\`
OPTIONS (
  object_metadata = 'SIMPLE',
  uris = ['gs://$DEVSHELL_PROJECT_ID-bucket/gsp1246/images/*']
  );
"

sleep 30

# Step 8: Creating or replacing gemini_pro model
echo "${YELLOW}${BOLD}Creating or replacing gemini_pro model${RESET}"
bq query --use_legacy_sql=false \
"
CREATE OR REPLACE MODEL \`gemini_demo.gemini_pro\`
REMOTE WITH CONNECTION \`us.gemini_conn\`
OPTIONS (endpoint = 'gemini-pro')
"

sleep 30

# Step 9: Creating or replacing gemini_pro_vision model
echo "${BLUE}${BOLD}Creating or replacing gemini_pro_vision model${RESET}"
bq query --use_legacy_sql=false \
"
CREATE OR REPLACE MODEL \`gemini_demo.gemini_pro_vision\`
REMOTE WITH CONNECTION \`us.gemini_conn\`
OPTIONS (endpoint = 'gemini-pro-vision')
"

sleep 30

# Step 10: Generating text for review images
echo "${RED}${BOLD}Generating text for review images${RESET}"
bq query --use_legacy_sql=false \
"
CREATE OR REPLACE TABLE
\`gemini_demo.review_images_results\` AS (
SELECT
    uri,
    ml_generate_text_llm_result
FROM
    ML.GENERATE_TEXT( MODEL \`gemini_demo.gemini_pro_vision\`,
    TABLE \`gemini_demo.review_images\`,
    STRUCT( 0.2 AS temperature,
        'For each image, provide a summary of what is happening in the image and keywords from the summary. Answer in JSON format with two keys: summary, keywords. Summary should be a string, keywords should be a list.' AS PROMPT,
        TRUE AS FLATTEN_JSON_OUTPUT)));
"

sleep 30

# Step 11: Generating text for review images
echo "${RED}${BOLD}Generating text for review images${RESET}"
bq query --use_legacy_sql=false \
"
CREATE OR REPLACE TABLE
\`gemini_demo.review_images_results\` AS (
SELECT
    uri,
    ml_generate_text_llm_result
FROM
    ML.GENERATE_TEXT( MODEL \`gemini_demo.gemini_pro_vision\`,
    TABLE \`gemini_demo.review_images\`,
    STRUCT( 0.2 AS temperature,
        'For each image, provide a summary of what is happening in the image and keywords from the summary. Answer in JSON format with two keys: summary, keywords. Summary should be a string, keywords should be a list.' AS PROMPT,
        TRUE AS FLATTEN_JSON_OUTPUT)));
"

# Step 12: Viewing the generated results
echo "${MAGENTA}${BOLD}Viewing the generated results${RESET}"
bq query --use_legacy_sql=false \
"
SELECT * FROM \`gemini_demo.review_images_results\`
"

# Step 13: Formatting the review images results
echo "${CYAN}${BOLD}Formatting the review images results${RESET}"
bq query --use_legacy_sql=false \
'
CREATE OR REPLACE TABLE
  `gemini_demo.review_images_results_formatted` AS (
  SELECT
    uri,
    JSON_QUERY(RTRIM(LTRIM(results.ml_generate_text_llm_result, " ```json"), "```"), "$.summary") AS summary,
    JSON_QUERY(RTRIM(LTRIM(results.ml_generate_text_llm_result, " ```json"), "```"), "$.keywords") AS keywords
  FROM
    `gemini_demo.review_images_results` results )
'

# Step 14: Viewing the formatted review images results
echo "${GREEN}${BOLD}Viewing the formatted review images results${RESET}"
bq query --use_legacy_sql=false \
"
SELECT * FROM \`gemini_demo.review_images_results_formatted\`
"

# Step 15: Generating customer reviews keywords
echo "${YELLOW}${BOLD}Generating customer reviews keywords${RESET}"
bq query --use_legacy_sql=false \
"
CREATE OR REPLACE TABLE
\`gemini_demo.customer_reviews_keywords\` AS (
SELECT ml_generate_text_llm_result, social_media_source, review_text, customer_id, location_id, review_datetime
FROM
ML.GENERATE_TEXT(
MODEL \`gemini_demo.gemini_pro\`,
(
   SELECT social_media_source, customer_id, location_id, review_text, review_datetime, CONCAT(
      'For each review, provide keywords from the review. Answer in JSON format with one key: keywords. Keywords should be a list.',
      review_text) AS prompt
   FROM \`gemini_demo.customer_reviews\`
),
STRUCT(
   0.2 AS temperature, TRUE AS flatten_json_output)));
"

# Step 16: Viewing customer reviews keywords
echo "${BLUE}${BOLD}Viewing customer reviews keywords${RESET}"
bq query --use_legacy_sql=false \
"
SELECT * FROM \`gemini_demo.customer_reviews_keywords\`
"

# Step 17: Generating sentiment analysis for customer reviews
echo "${RED}${BOLD}Generating sentiment analysis for customer reviews${RESET}"
bq query --use_legacy_sql=false "
CREATE OR REPLACE TABLE \`gemini_demo.customer_reviews_analysis\` AS (
  SELECT 
    ml_generate_text_llm_result, 
    social_media_source, 
    review_text, 
    customer_id, 
    location_id, 
    review_datetime
  FROM
    ML.GENERATE_TEXT(
      MODEL \`gemini_demo.gemini_pro\`,
      (
        SELECT 
          social_media_source, 
          customer_id, 
          location_id, 
          review_text, 
          review_datetime, 
          CONCAT(
            'Classify the sentiment of the following text as positive or negative.',
            review_text, 
            'In your response don\'t include the sentiment explanation. Remove all extraneous information from your response, it should be a boolean response either positive or negative.'
          ) AS prompt
        FROM \`gemini_demo.customer_reviews\`
      ),
      STRUCT(
        0.2 AS temperature, 
        TRUE AS flatten_json_output
      )
    )
);
"

# Step 18: Viewing customer reviews sentiment analysis
echo "${MAGENTA}${BOLD}Viewing customer reviews sentiment analysis${RESET}"
bq query --use_legacy_sql=false \
"
SELECT * FROM \`gemini_demo.customer_reviews_analysis\`
ORDER BY review_datetime
"

# Step 19: Creating cleaned data view for customer reviews
echo "${CYAN}${BOLD}Creating cleaned data view for customer reviews${RESET}"
bq query --use_legacy_sql=false \
"
CREATE OR REPLACE VIEW gemini_demo.cleaned_data_view AS
SELECT REPLACE(REPLACE(LOWER(ml_generate_text_llm_result), '.', ''), ' ', '') AS sentiment, 
REGEXP_REPLACE(
      REGEXP_REPLACE(
            REGEXP_REPLACE(social_media_source, r'Google(\+|\sReviews|\sLocal|\sMy\sBusiness|\sreviews|\sMaps)?', 'Google'), 
            'YELP', 'Yelp'
      ),
      r'SocialMedia1?', 'Social Media'
   ) AS social_media_source,
review_text, customer_id, location_id, review_datetime
FROM \`gemini_demo.customer_reviews_analysis\`;
"

# Step 20: Viewing cleaned data view
echo "${GREEN}${BOLD}Viewing cleaned data view${RESET}"
bq query --use_legacy_sql=false \
"
SELECT * FROM \`gemini_demo.cleaned_data_view\`
ORDER BY review_datetime
"

# Step 21: Counting sentiment occurrences
echo "${YELLOW}${BOLD}Counting sentiment occurrences${RESET}"
bq query --use_legacy_sql=false \
"
SELECT sentiment, COUNT(*) AS count
FROM \`gemini_demo.cleaned_data_view\`
WHERE sentiment IN ('positive', 'negative')
GROUP BY sentiment; 
"

# Step 22: Counting sentiment by social media source
echo "${RED}${BOLD}Counting sentiment by social media source${RESET}"
bq query --use_legacy_sql=false \
"
SELECT sentiment, social_media_source, COUNT(*) AS count
FROM \`gemini_demo.cleaned_data_view\`
WHERE sentiment IN ('positive') OR sentiment IN ('negative')
GROUP BY sentiment, social_media_source
ORDER BY sentiment, count;    
"

# Step 23: Generating marketing incentives for reviews
echo "${GREEN}${BOLD}Generating marketing incentives for reviews${RESET}"
bq query --use_legacy_sql=false \
"
CREATE OR REPLACE TABLE
\`gemini_demo.customer_reviews_marketing\` AS (
SELECT ml_generate_text_llm_result, social_media_source, review_text, customer_id, location_id, review_datetime
FROM
ML.GENERATE_TEXT(
MODEL \`gemini_demo.gemini_pro\`,
(
   SELECT social_media_source, customer_id, location_id, review_text, review_datetime, CONCAT(
      'You are a marketing representative. How could we incentivise this customer with this positive review? Provide a single response, and should be simple and concise, do not include emojis. Answer in JSON format with one key: marketing. Marketing should be a string.', review_text) AS prompt
   FROM \`gemini_demo.customer_reviews\`
   WHERE customer_id = 5576
),
STRUCT(
   0.2 AS temperature, TRUE AS flatten_json_output)));
"

# Step 24: Viewing the customer reviews marketing table
echo "${YELLOW}${BOLD}Viewing the customer reviews marketing table${RESET}"
bq query --use_legacy_sql=false \
"
SELECT * FROM \`gemini_demo.customer_reviews_marketing\`
"

# Step 25: Formatting the marketing responses
echo "${BLUE}${BOLD}Formatting the marketing responses${RESET}"
bq query --use_legacy_sql=false \
'
CREATE OR REPLACE TABLE
`gemini_demo.customer_reviews_marketing_formatted` AS (
SELECT
   review_text,
   JSON_QUERY(RTRIM(LTRIM(results.ml_generate_text_llm_result, " ```json"), "```"), "$.marketing") AS marketing,
   social_media_source, customer_id, location_id, review_datetime
FROM
   `gemini_demo.customer_reviews_marketing` results )
'

# Step 26: Viewing the formatted marketing responses
echo "${MAGENTA}${BOLD}Viewing the formatted marketing responses${RESET}"
bq query --use_legacy_sql=false \
"
SELECT * FROM \`gemini_demo.customer_reviews_marketing_formatted\`
"

# Step 27: Generating customer service responses for reviews
echo "${CYAN}${BOLD}Generating customer service responses for reviews${RESET}"
bq query --use_legacy_sql=false \
"
CREATE OR REPLACE TABLE
\`gemini_demo.customer_reviews_cs_response\` AS (
SELECT ml_generate_text_llm_result, social_media_source, review_text, customer_id, location_id, review_datetime
FROM
ML.GENERATE_TEXT(
MODEL \`gemini_demo.gemini_pro\`,
(
   SELECT social_media_source, customer_id, location_id, review_text, review_datetime, CONCAT(
      'How would you respond to this customer review? If the customer says the coffee is weak or burnt, respond stating "thank you for the review we will provide your response to the location that you did not like the coffee and it could be improved." Or if the review states the service is bad, respond to the customer stating, "the location they visited has been notfied and we are taking action to improve our service at that location." From the customer reviews provide actions that the location can take to improve. The response and the actions should be simple, and to the point. Do not include any extraneous or special characters in your response. Answer in JSON format with two keys: Response, and Actions. Response should be a string. Actions should be a string.', review_text) AS prompt
   FROM \`gemini_demo.customer_reviews\`
   WHERE customer_id = 8844
),
STRUCT(
   0.2 AS temperature, TRUE AS flatten_json_output)));
"

# Step 28: Viewing customer service responses
echo "${GREEN}${BOLD}Viewing customer service responses${RESET}"
bq query --use_legacy_sql=false \
"
SELECT * FROM \`gemini_demo.customer_reviews_cs_response\`
"

# Step 29: Formatting the customer service responses
echo "${YELLOW}${BOLD}Formatting the customer service responses${RESET}"
bq query --use_legacy_sql=false \
'
CREATE OR REPLACE TABLE
`gemini_demo.customer_reviews_cs_response_formatted` AS (
SELECT
   review_text,
   JSON_QUERY(RTRIM(LTRIM(results.ml_generate_text_llm_result, " ```json"), "```"), "$.Response") AS Response,
   JSON_QUERY(RTRIM(LTRIM(results.ml_generate_text_llm_result, " ```json"), "```"), "$.Actions") AS Actions,
   social_media_source, customer_id, location_id, review_datetime
FROM
   `gemini_demo.customer_reviews_cs_response` results )
'

# Step 30: Viewing the formatted customer service responses
echo "${BLUE}${BOLD}Viewing the formatted customer service responses${RESET}"
bq query --use_legacy_sql=false \
"
SELECT * FROM \`gemini_demo.customer_reviews_cs_response_formatted\`
"

# Step 31: Generating results from review images with model gemini_pro_vision
echo "${RED}${BOLD}Generating results from review images with model gemini_pro_vision${RESET}"
bq query --use_legacy_sql=false '
CREATE OR REPLACE TABLE
`gemini_demo.review_images_results` AS (
SELECT
    uri,
    ml_generate_text_llm_result
FROM
    ML.GENERATE_TEXT( MODEL `gemini_demo.gemini_pro_vision`,
    TABLE `gemini_demo.review_images`,
    STRUCT( 0.2 AS temperature,
        "For each image, provide a summary of what is happening in the image and keywords from the summary. Answer in JSON format with two keys: summary, keywords. Summary should be a string, keywords should be a list." AS PROMPT,
        TRUE AS FLATTEN_JSON_OUTPUT)));'

# Step 32: Viewing the final review images results
echo "${GREEN}${BOLD}Viewing the final review images results${RESET}"
bq query --use_legacy_sql=false \
"
SELECT * FROM \`gemini_demo.review_images_results\`
"

# Step 33: Formatting the review images results
echo "${YELLOW}${BOLD}Formatting the review images results${RESET}"
bq query --use_legacy_sql=false \
'
CREATE OR REPLACE TABLE
  `gemini_demo.review_images_results_formatted` AS (
  SELECT
    uri,
    JSON_QUERY(RTRIM(LTRIM(results.ml_generate_text_llm_result, " ```json"), "```"), "$.summary") AS summary,
    JSON_QUERY(RTRIM(LTRIM(results.ml_generate_text_llm_result, " ```json"), "```"), "$.keywords") AS keywords
  FROM
    `gemini_demo.review_images_results` results )
'

# Step 34: Viewing the formatted review images results
echo "${CYAN}${BOLD}Viewing the formatted review images results${RESET}"
bq query --use_legacy_sql=false \
"
SELECT * FROM \`gemini_demo.review_images_results_formatted\`
"

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