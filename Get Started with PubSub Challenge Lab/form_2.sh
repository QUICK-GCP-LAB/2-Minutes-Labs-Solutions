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

gcloud pubsub schemas create city-temp-schema \
        --type=avro \
        --definition='{                                             
            "type" : "record",                               
            "name" : "Avro",                                 
            "fields" : [                                     
            {                                                
                "name" : "city",                             
                "type" : "string"                            
            },                                               
            {                                                
                "name" : "temperature",                      
                "type" : "double"                            
            },                                               
            {                                                
                "name" : "pressure",                         
                "type" : "int"                               
            },                                               
            {                                                
                "name" : "time_position",                    
                "type" : "string"                            
            }                                                
        ]                                                    
    }'


gcloud pubsub topics create temp-topic \
        --message-encoding=JSON \
        --schema=temperature-schema

mkdir gcf_hello_world && cd $_

cat > index.js <<'EOF_END'
/**
 * Triggered from a message on a Cloud Pub/Sub topic.
 *
 * @param {!Object} event Event payload.
 * @param {!Object} context Metadata for the event.
 */
exports.helloPubSub = (event, context) => {
  const message = event.data
    ? Buffer.from(event.data, 'base64').toString()
    : 'Hello, World';
  console.log(message);
};
EOF_END

cat > package.json <<'EOF_END'
{
  "name": "sample-pubsub",
  "version": "0.0.1",
  "dependencies": {
    "@google-cloud/pubsub": "^0.18.0"
  }
}
EOF_END

deploy_function() {
gcloud functions deploy gcf-pubsub \
  --trigger-topic=gcf-topic \
  --runtime=nodejs20 \
  --no-gen2 \
  --entry-point=helloPubSub \
  --source=. \
  --region=$LOCATION
}

deploy_success=false

while [ "$deploy_success" = false ]; do
    if deploy_function; then
        echo "Function deployed successfully..."
        deploy_success=true
    else
        echo "Retrying in 20 seconds..."
        sleep 20
    fi
done

echo "${BG_RED}${BOLD}Congratulations For Completing The Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#
