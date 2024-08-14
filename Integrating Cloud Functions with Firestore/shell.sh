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

PROJECT_ID=$(gcloud config get-value project)

PROJECT_NUMBER=$(gcloud projects list \
 --filter="project_id:$PROJECT_ID" \
 --format='value(project_number)')

 gcloud config set functions/region $REGION

gcloud services enable \
  artifactregistry.googleapis.com \
  cloudfunctions.googleapis.com \
  cloudbuild.googleapis.com \
  eventarc.googleapis.com \
  run.googleapis.com \
  logging.googleapis.com \
  storage.googleapis.com \
  pubsub.googleapis.com

gcloud storage cp -R gs://cloud-training/CBL493/firestore_functions .

cd firestore_functions

cat > index.js <<'EOF_END'
 /**
  * Cloud Event Function triggered by a change to a Firestore document.
  */
 const functions = require('@google-cloud/functions-framework');
 const protobuf = require('protobufjs');

 functions.cloudEvent('newCustomer', async cloudEvent => {
   console.log(`Function triggered by event on: ${cloudEvent.source}`);
   console.log(`Event type: ${cloudEvent.type}`);

   console.log('Loading protos...');
   const root = await protobuf.load('data.proto');
   const DocumentEventData = root.lookupType('google.events.cloud.firestore.v1.DocumentEventData');

   console.log('Decoding data...');
   const firestoreReceived = DocumentEventData.decode(cloudEvent.data);

   console.log('\nNew document:');
   console.log(JSON.stringify(firestoreReceived.value, null, 2));
 });
EOF_END


cat > package.json <<'EOF_END'
{
    "name": "firestore_functions",
    "version": "0.0.1",
    "main": "index.js",
    "dependencies": {
      "@google-cloud/functions-framework": "^3.1.3",
      "protobufjs": "^7.2.2",
      "@google-cloud/firestore": "^6.0.0"
    }
   }
EOF_END

SERVICE_ACCOUNT=service-$PROJECT_NUMBER@gcf-admin-robot.iam.gserviceaccount.com

gcloud projects add-iam-policy-binding $PROJECT_ID --member serviceAccount:$SERVICE_ACCOUNT --role roles/artifactregistry.reader

gcloud services disable cloudfunctions.googleapis.com

gcloud services enable cloudfunctions.googleapis.com

gcloud projects add-iam-policy-binding $PROJECT_ID --member serviceAccount:$SERVICE_ACCOUNT --role roles/artifactregistry.reader

# Your existing deployment command
deploy_function() {
gcloud functions deploy newCustomer \
--gen2 \
--runtime=nodejs20 \
--region=$REGION \
--trigger-location=$REGION \
--source=. \
--entry-point=newCustomer \
--trigger-event-filters=type=google.cloud.firestore.document.v1.created \
--trigger-event-filters=database='(default)' \
--trigger-event-filters-path-pattern=document='customers/{name}'
}

# Variables
SERVICE_NAME="newCustomer"

# Loop until the Cloud Function is deployed
while true; do
  # Run the deployment command
  deploy_function

  # Check if Cloud Function is deployed
  if gcloud functions describe $SERVICE_NAME --region $REGION &> /dev/null; then
    echo "Cloud Function is deployed. Exiting the loop."
    break
  else
    echo "Waiting for Cloud Function to be deployed..."
    sleep 10
  fi
done

cat > index.js <<'EOF_END'
 /**
  * Cloud Event Function triggered by a change to a Firestore document.
  */
 const functions = require('@google-cloud/functions-framework');
 const protobuf = require('protobufjs');

 functions.cloudEvent('newCustomer', async cloudEvent => {
   console.log(`Function triggered by event on: ${cloudEvent.source}`);
   console.log(`Event type: ${cloudEvent.type}`);

   console.log('Loading protos...');
   const root = await protobuf.load('data.proto');
   const DocumentEventData = root.lookupType('google.events.cloud.firestore.v1.DocumentEventData');

   console.log('Decoding data...');
   const firestoreReceived = DocumentEventData.decode(cloudEvent.data);

   console.log('\nNew document:');
   console.log(JSON.stringify(firestoreReceived.value, null, 2));
 });

const Firestore = require('@google-cloud/firestore');
const firestore = new Firestore({
  projectId: process.env.GOOGLE_CLOUD_PROJECT,
});

functions.cloudEvent('updateCustomer', async cloudEvent => {
  console.log('Loading protos...');
  const root = await protobuf.load('data.proto');
  const DocumentEventData = root.lookupType(
   'google.events.cloud.firestore.v1.DocumentEventData'
  );

  console.log('Decoding data...');
  const firestoreReceived = DocumentEventData.decode(cloudEvent.data);

  const resource = firestoreReceived.value.name;
  const affectedDoc = firestore.doc(resource.split('/documents/')[1]);

  // Fullname already exists, so don't update again to avoid infinite loop.
  if (firestoreReceived.value.fields.hasOwnProperty('fullname')) {
    console.log('Fullname is already present in document.');
    return;
  }

  if (firestoreReceived.value.fields.hasOwnProperty('lastname')) {
    const lname = firestoreReceived.value.fields.lastname.stringValue;
    const fname = firestoreReceived.value.fields.firstname.stringValue;
    const fullname = `${fname} ${lname}`
    console.log(`Adding fullname --> ${fullname}`);
    await affectedDoc.update({
     fullname: fullname
    });
  }
});
EOF_END

deploy_function() {
gcloud functions deploy updateCustomer \
--gen2 \
--runtime=nodejs20 \
--region=$REGION \
--trigger-location=$REGION \
--source=. \
--entry-point=updateCustomer \
--trigger-event-filters=type=google.cloud.firestore.document.v1.updated \
--trigger-event-filters=database='(default)' \
--trigger-event-filters-path-pattern=document='customers/{name}'
}

# Variables
SERVICE_NAME="updateCustomer"

# Loop until the Cloud Function is deployed
while true; do
  # Run the deployment command
  deploy_function

  # Check if Cloud Function is deployed
  if gcloud functions describe $SERVICE_NAME --region $REGION &> /dev/null; then
    echo "Cloud Function is deployed. Exiting the loop."
    break
  else
    echo "Waiting for Cloud Function to be deployed..."
    sleep 15
  fi
done

gcloud services enable secretmanager.googleapis.com

echo -n "secret_api_key" | gcloud secrets create api-cred --replication-policy="automatic" --data-file=-

gcloud secrets add-iam-policy-binding api-cred --member=serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com --project=$PROJECT_ID --role='roles/secretmanager.secretAccessor'

cat > index.js <<'EOF_END'
 /**
  * Cloud Event Function triggered by a change to a Firestore document.
  */
 const functions = require('@google-cloud/functions-framework');
 const protobuf = require('protobufjs');

 functions.cloudEvent('newCustomer', async cloudEvent => {
   console.log(`Function triggered by event on: ${cloudEvent.source}`);
   console.log(`Event type: ${cloudEvent.type}`);

   console.log('Loading protos...');
   const root = await protobuf.load('data.proto');
   const DocumentEventData = root.lookupType('google.events.cloud.firestore.v1.DocumentEventData');

   console.log('Decoding data...');
   const firestoreReceived = DocumentEventData.decode(cloudEvent.data);

   console.log('\nNew document:');
   console.log(JSON.stringify(firestoreReceived.value, null, 2));
 });
 
const Firestore = require('@google-cloud/firestore');
const firestore = new Firestore({
  projectId: process.env.GOOGLE_CLOUD_PROJECT,
});

functions.cloudEvent('updateCustomer', async cloudEvent => {
  console.log('Loading protos...');
  const root = await protobuf.load('data.proto');
  const DocumentEventData = root.lookupType(
   'google.events.cloud.firestore.v1.DocumentEventData'
  );

  console.log('Decoding data...');
  const firestoreReceived = DocumentEventData.decode(cloudEvent.data);

  const resource = firestoreReceived.value.name;
  const affectedDoc = firestore.doc(resource.split('/documents/')[1]);

  // Fullname already exists, so don't update again to avoid infinite loop.
  if (firestoreReceived.value.fields.hasOwnProperty('fullname')) {
    console.log('Fullname is already present in document.');
     // BEGIN access a secret
 const fs = require('fs/promises');
 try {
   const secret = await fs.readFile('/etc/secrets/api_cred/latest', { encoding: 'utf8' });
   // use the secret. For lab testing purposes, we log the secret.
   console.log('secret: ', secret);
 } catch (err) {
   console.log(err);
 }
 // End access a secret
    return;
  }

  if (firestoreReceived.value.fields.hasOwnProperty('lastname')) {
    const lname = firestoreReceived.value.fields.lastname.stringValue;
    const fname = firestoreReceived.value.fields.firstname.stringValue;
    const fullname = `${fname} ${lname}`
    console.log(`Adding fullname --> ${fullname}`);
    await affectedDoc.update({
     fullname: fullname
    });
  }
});
EOF_END

deploy_function() {
    gcloud functions deploy newCustomer \
    --gen2 \
    --runtime=nodejs20 \
    --region=$REGION \
    --trigger-location=$REGION \
    --source=. \
    --entry-point=newCustomer \
    --trigger-event-filters=type=google.cloud.firestore.document.v1.created \
    --trigger-event-filters=database='(default)' \
    --trigger-event-filters-path-pattern=document='customers/{name}' \
    --set-secrets '/etc/secrets/api_cred/latest=api-cred:latest'
}


# Variables
SERVICE_NAME="newCustomer"

# Loop until the Cloud Function is deployed
while true; do
  # Run the deployment command
  deploy_function

  # Check if Cloud Function is deployed
  if gcloud functions describe $SERVICE_NAME --region $REGION &> /dev/null; then
    echo "Cloud Function is deployed. Exiting the loop."
    break
  else
    echo "Waiting for Cloud Function to be deployed..."
    sleep 15
  fi
done

echo "${BG_RED}${BOLD}Congratulations For Completing The Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#