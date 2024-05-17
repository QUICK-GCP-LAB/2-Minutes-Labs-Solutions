

gcloud services enable language.googleapis.com

ZONE="$(gcloud compute instances list --project=$DEVSHELL_PROJECT_ID --format='value(ZONE)')"

gcloud compute instances add-metadata linux-instance --metadata API_KEY="$KEY" --project=$DEVSHELL_PROJECT_ID --zone=$ZONE

cat > prepare_disk.sh <<'EOF_END'

API_KEY=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/attributes/API_KEY)

export API_KEY="$API_KEY"  # Export the API key to the script

cat > request.json <<EOF
{
    "document":{
      "type":"PLAIN_TEXT",
      "content":"A Smoky Lobster Salad With a Tapa Twist. This spin on the Spanish pulpo a la gallega skips the octopus, but keeps the sea salt, olive oil, pimentón and boiled potatoes."
    }
  }
EOF


curl "https://language.googleapis.com/v1/documents:classifyText?key=${API_KEY}" \
  -s -X POST -H "Content-Type: application/json" --data-binary @request.json

  curl "https://language.googleapis.com/v1/documents:classifyText?key=${API_KEY}" \
  -s -X POST -H "Content-Type: application/json" --data-binary @request.json > result.json

EOF_END

gcloud compute scp prepare_disk.sh linux-instance:/tmp --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet

gcloud compute ssh linux-instance --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet --command="export API_KEY=$KEY && bash /tmp/prepare_disk.sh"

bq --location=US mk --dataset $DEVSHELL_PROJECT_ID:news_classification_dataset

bq mk --table $DEVSHELL_PROJECT_ID:news_classification_dataset.article_data article_text:STRING,category:STRING,confidence:FLOAT

echo "${RED}${BOLD}Congratulations${RESET}" "${WHITE}${BOLD}for${RESET}" "${GREEN}${BOLD}Completing the Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#