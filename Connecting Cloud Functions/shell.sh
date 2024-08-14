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

export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_ID=$DEVSHELL_PROJECT_ID

gcloud config set compute/zone $ZONE
export REGION="${ZONE%-*}"
gcloud config set compute/region $REGION

export PROJECT_NUMBER=$(gcloud projects describe $DEVSHELL_PROJECT_ID --format='value(projectNumber)')
gcloud config set project $DEVSHELL_PROJECT_ID

gcloud services enable \
  artifactregistry.googleapis.com \
  cloudfunctions.googleapis.com \
  cloudbuild.googleapis.com \
  eventarc.googleapis.com \
  run.googleapis.com \
  logging.googleapis.com \
  pubsub.googleapis.com \
  redis.googleapis.com \
  vpcaccess.googleapis.com

sleep 20

REDIS_INSTANCE=customerdb

gcloud redis instances create $REDIS_INSTANCE \
 --size=2 --region=$REGION \
 --redis-version=redis_6_x
 
gcloud redis instances describe $REDIS_INSTANCE --region=$REGION

REDIS_IP=$(gcloud redis instances describe $REDIS_INSTANCE --region=$REGION --format="value(host)"); echo $REDIS_IP

REDIS_PORT=$(gcloud redis instances describe $REDIS_INSTANCE --region=$REGION --format="value(port)"); echo $REDIS_PORT

gcloud compute networks vpc-access connectors create test-connector --region=$REGION --machine-type=e2-micro --network=default --range=10.8.0.0/28 --max-instances=10 --min-instances=2

gcloud compute networks vpc-access connectors \
  describe test-connector \
  --region $REGION

TOPIC=add_redis

gcloud pubsub topics create $TOPIC

mkdir ~/redis-pubsub && cd $_
touch main.py && touch requirements.txt

cat > main.py <<'EOF_CP'
import os
import base64
import json
import redis
import functions_framework

redis_host = os.environ.get('REDISHOST', 'localhost')
redis_port = int(os.environ.get('REDISPORT', 6379))
redis_client = redis.StrictRedis(host=redis_host, port=redis_port)

# Triggered from a message on a Pub/Sub topic.
@functions_framework.cloud_event
def addToRedis(cloud_event):
    # The Pub/Sub message data is stored as a base64-encoded string in the cloud_event.data property
    # The expected value should be a JSON string.
    json_data_str = base64.b64decode(cloud_event.data["message"]["data"]).decode()
    json_payload = json.loads(json_data_str)
    response_data = ""
    if json_payload and 'id' in json_payload:
        id = json_payload['id']
        data = redis_client.set(id, json_data_str)
        response_data = redis_client.get(id)
        print(f"Added data to Redis: {response_data}")
    else:
        print("Message is invalid, or missing an 'id' attribute")
EOF_CP


cat > requirements.txt <<EOF_CP
functions-framework==3.2.0
redis==4.3.4
EOF_CP

deploy_function() {
    gcloud functions deploy python-pubsub-function \
    --runtime=python310 \
    --region=$REGION \
    --source=. \
    --entry-point=addToRedis \
    --trigger-topic=$TOPIC \
    --vpc-connector projects/$PROJECT_ID/locations/$REGION/connectors/test-connector \
    --set-env-vars REDISHOST=$REDIS_IP,REDISPORT=$REDIS_PORT
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

gcloud pubsub topics publish $TOPIC --message='{"id": 1234, "firstName": "Lucas" ,"lastName": "Sherman", "Phone": "555-555-5555"}'

sleep 10

mkdir ~/redis-http && cd $_
touch main.py && touch requirements.txt

cat > main.py <<'EOF_CP'
import os
import redis
from flask import request
import functions_framework

redis_host = os.environ.get('REDISHOST', 'localhost')
redis_port = int(os.environ.get('REDISPORT', 6379))
redis_client = redis.StrictRedis(host=redis_host, port=redis_port)

@functions_framework.http
def getFromRedis(request):
    response_data = ""
    if request.method == 'GET':
        id = request.args.get('id')
        try:
            response_data = redis_client.get(id)
        except RuntimeError:
            response_data = ""
        if response_data is None:
            response_data = ""
    return response_data
EOF_CP


cat > requirements.txt <<EOF_CP
functions-framework==3.2.0
redis==4.3.4
EOF_CP

deploy_function() {
gcloud functions deploy http-get-redis \
--gen2 \
--runtime python310 \
--entry-point getFromRedis \
--source . \
--region $REGION \
--trigger-http \
--timeout 600s \
--max-instances 1 \
--vpc-connector projects/$PROJECT_ID/locations/$REGION/connectors/test-connector \
--set-env-vars REDISHOST=$REDIS_IP,REDISPORT=$REDIS_PORT \
--no-allow-unauthenticated
}

deploy_success=false

while [ "$deploy_success" = false ]; do
    if deploy_function; then
        echo "Function deployed successfully..."
        deploy_success=true
    else
        echo "Retrying in 20 seconds..."
        sleep 30
    fi
done

FUNCTION_URI=$(gcloud functions describe http-get-redis --gen2 --region $REGION --format "value(serviceConfig.uri)"); echo $FUNCTION_URI

curl -H "Authorization: bearer $(gcloud auth print-identity-token)" "${FUNCTION_URI}?id=1234"

gsutil cp gs://cloud-training/CBL492/startup.sh .

cat startup.sh

gcloud compute instances create webserver-vm \
--image-project=debian-cloud \
--image-family=debian-11 \
--metadata-from-file=startup-script=./startup.sh \
--machine-type e2-standard-2 \
--tags=http-server \
--scopes=https://www.googleapis.com/auth/cloud-platform \
--zone $ZONE

gcloud compute --project=$PROJECT_ID \
 firewall-rules create default-allow-http \
 --direction=INGRESS \
 --priority=1000 \
 --network=default \
 --action=ALLOW \
 --rules=tcp:80 \
 --source-ranges=0.0.0.0/0 \
 --target-tags=http-server


sleep 30

VM_INT_IP=$(gcloud compute instances describe webserver-vm --format='get(networkInterfaces[0].networkIP)' --zone $ZONE); echo $VM_INT_IP

VM_EXT_IP=$(gcloud compute instances describe webserver-vm --format='get(networkInterfaces[0].accessConfigs[0].natIP)' --zone $ZONE); echo $VM_EXT_IP

mkdir ~/vm-http && cd $_
touch main.py && touch requirements.txt

cat > main.py <<'EOF_CP'
import functions_framework
import requests

@functions_framework.http
def connectVM(request):
    resp_text = ""
    if request.method == 'GET':
        ip = request.args.get('ip')
        try:
            response_data = requests.get(f"http://{ip}")
            resp_text = response_data.text
        except RuntimeError:
            print ("Error while connecting to VM")
    return resp_text
EOF_CP

cat > requirements.txt <<EOF_END
functions-framework==3.2.0
Werkzeug==2.3.7
flask==2.1.3
requests==2.28.1
EOF_END


deploy_function() {
gcloud functions deploy vm-connector \
 --runtime python310 \
 --entry-point connectVM \
 --source . \
 --region $REGION \
 --trigger-http \
 --timeout 10s \
 --max-instances 1 \
 --no-allow-unauthenticated
}

deploy_success=false

while [ "$deploy_success" = false ]; do
    if deploy_function; then
        echo "Function deployed successfully..."
        deploy_success=true
    else
        echo "Retrying in 30 seconds..."
        sleep 30
    fi
done

FUNCTION_URI=$(gcloud functions describe vm-connector --region $REGION --format='value(httpsTrigger.url)'); echo $FUNCTION_URI

curl -H "Authorization: bearer $(gcloud auth print-identity-token)" "${FUNCTION_URI}?ip=$VM_INT_IP"

curl -H "Authorization: bearer $(gcloud auth print-identity-token)" "${FUNCTION_URI}?ip=$VM_EXT_IP"

gcloud services disable cloudfunctions.googleapis.com

gcloud services enable cloudfunctions.googleapis.com

sleep 30

cd ~
cd vm-http

export PROJECT_NUMBER=$(gcloud projects describe $DEVSHELL_PROJECT_ID --format='value(projectNumber)')
export PROJECT_ID=$(gcloud config get-value project)

deploy_function() {
    gcloud functions deploy vm-connector \
        --runtime python310 \
        --entry-point connectVM \
        --source . \
        --region $REGION \
        --trigger-http \
        --timeout 10s \
        --max-instances 1 \
        --no-allow-unauthenticated \
        --vpc-connector projects/$PROJECT_ID/locations/$REGION/connectors/test-connector \
        --service-account "$PROJECT_NUMBER-compute@developer.gserviceaccount.com"
}

deploy_success=false

export SERVICE_NAME="vm-connector"

while [ "$deploy_success" = false ]; do
    deploy_function
    if gcloud functions describe $SERVICE_NAME --region=$REGION &> /dev/null; then
        echo "Function deployed successfully..."
        deploy_success=true
    else
        echo "Retrying in 30 seconds..."
        sleep 30
    fi
done

curl -H "Authorization: bearer $(gcloud auth print-identity-token)" "${FUNCTION_URI}?ip=$VM_INT_IP"

gcloud pubsub topics publish $TOPIC --message='{"id": 1234, "firstName": "Lucas" ,"lastName": "Sherman", "Phone": "555-555-5555"}'

TOPIC=add_redis

cd ~
mkdir ~/redis-pubsub && cd $_
touch main.py && touch requirements.txt

cat > main.py <<'EOF_CP'
import os
import base64
import json
import redis
import functions_framework

redis_host = os.environ.get('REDISHOST', 'localhost')
redis_port = int(os.environ.get('REDISPORT', 6379))
redis_client = redis.StrictRedis(host=redis_host, port=redis_port)

# Triggered from a message on a Pub/Sub topic.
@functions_framework.cloud_event
def addToRedis(cloud_event):
    # The Pub/Sub message data is stored as a base64-encoded string in the cloud_event.data property
    # The expected value should be a JSON string.
    json_data_str = base64.b64decode(cloud_event.data["message"]["data"]).decode()
    json_payload = json.loads(json_data_str)
    response_data = ""
    if json_payload and 'id' in json_payload:
        id = json_payload['id']
        data = redis_client.set(id, json_data_str)
        response_data = redis_client.get(id)
        print(f"Added data to Redis: {response_data}")
    else:
        print("Message is invalid, or missing an 'id' attribute")
EOF_CP


cat > requirements.txt <<EOF_CP
functions-framework==3.2.0
redis==4.3.4
EOF_CP

deploy_function() {
    gcloud functions deploy python-pubsub-function \
    --runtime=python310 \
    --region=$REGION \
    --source=. \
    --entry-point=addToRedis \
    --trigger-topic=$TOPIC \
    --vpc-connector projects/$PROJECT_ID/locations/$REGION/connectors/test-connector \
    --set-env-vars REDISHOST=$REDIS_IP,REDISPORT=$REDIS_PORT
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
