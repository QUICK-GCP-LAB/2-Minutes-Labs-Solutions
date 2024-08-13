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

export PROJECT_NUMBER=$(gcloud projects describe $DEVSHELL_PROJECT_ID --format='value(projectNumber)')
gcloud config set project $DEVSHELL_PROJECT_ID

gcloud services enable \
  artifactregistry.googleapis.com \
  cloudfunctions.googleapis.com \
  cloudbuild.googleapis.com \
  eventarc.googleapis.com \
  run.googleapis.com \
  logging.googleapis.com \
  storage.googleapis.com \
  pubsub.googleapis.com

sleep 20

mkdir techcps && cd techcps

cat > index.js <<EOF_END
const functions = require('@google-cloud/functions-framework');

functions.http('convertTemp', (req, res) => {
 var dirn = req.query.convert;
 var ctemp = (req.query.temp - 32) * 5/9;
 var target_unit = 'Celsius';

 if (req.query.temp === undefined) {
    res.status(400);
    res.send('Temperature value not supplied in request.');
 }
 if (dirn === undefined)
   dirn = process.env.TEMP_CONVERT_TO;
 if (dirn === 'ctof') {
   ctemp = (req.query.temp * 9/5) + 32;
   target_unit = 'Fahrenheit';
 }

 res.send(`Temperature in ${target_unit} is: ${ctemp.toFixed(2)}.`);
});
EOF_END

cat > package.json <<EOF_CP
{
  "dependencies": {
    "@google-cloud/functions-framework": "^3.0.0"
  }
}
EOF_CP

deploy_function() {
gcloud functions deploy temperature-converter \
    --gen2 \
    --region $REGION \
    --runtime nodejs20 \
    --entry-point convertTemp \
    --source . \
    --trigger-http \
    --timeout 600s \
    --max-instances 1 \
    --no-allow-unauthenticated --quiet
}

deploy_success=false

while [ "$deploy_success" = false ]; do
    if deploy_function; then
        echo "Function deployed successfully..."
        deploy_success=true
    else
        echo "Retrying in 10 seconds..."
        sleep 15
    fi
done

FUNCTION_URI=$(gcloud functions describe temperature-converter --gen2 --region $REGION --format "value(serviceConfig.uri)"); echo $FUNCTION_URI

curl -H "Authorization: bearer $(gcloud auth print-identity-token)" "${FUNCTION_URI}?temp=70"

curl -H "Authorization: bearer $(gcloud auth print-identity-token)" "${FUNCTION_URI}?temp=21.11&convert=ctof"

SERVICE_ACCOUNT=$(gcloud storage service-agent)

gcloud projects add-iam-policy-binding $PROJECT_ID --member serviceAccount:$SERVICE_ACCOUNT --role roles/pubsub.publisher

gcloud storage cp gs://cloud-training/CBL491/data/average-temps.csv .

mkdir ~/temp-data-checker && cd $_

touch index.js && touch package.json

cat > index.js <<EOF_CP
const functions = require('@google-cloud/functions-framework');

// Register a CloudEvent callback with the Functions Framework that will
// be triggered by Cloud Storage events.
functions.cloudEvent('checkTempData', cloudEvent => {
  console.log('Event ID: ' + cloudEvent.id);
  console.log('Event Type: ' + cloudEvent.type);

  const file = cloudEvent.data;
  console.log('Bucket: ' + file.bucket);
  console.log('File: ' + file.name);
  console.log('Created: ' + file.timeCreated);
})
EOF_CP

cat > package.json <<EOF_CP
{
  "name": "temperature-data-checker",
  "version": "0.0.1",
  "main": "index.js",
  "dependencies": {
    "@google-cloud/functions-framework": "^2.1.0"
  }
}
EOF_CP

BUCKET="gs://gcf-temperature-data-$PROJECT_ID"

gsutil mb -l $REGION $BUCKET

deploy_function() {
gcloud functions deploy temperature-data-checker \
 --gen2 \
 --runtime nodejs20 \
 --entry-point checkTempData \
 --source . \
 --region $REGION \
 --trigger-bucket $BUCKET \
 --trigger-location $REGION \
 --max-instances 1 --quiet
}

deploy_success=false

while [ "$deploy_success" = false ]; do
    if deploy_function; then
        echo "Function deployed successfully..."
        deploy_success=true
    else
        echo "Retrying in 15 seconds..."
        sleep 15
    fi
done

cd ~
gsutil cp gs://cloud-training/CBL491/data/average-temps.csv .
gsutil cp ~/average-temps.csv $BUCKET/average-temps.csv

gcloud functions logs read temperature-data-checker \
 --region $REGION --gen2 --limit=100 --format "value(log)"

mkdir ~/temp-data-converter && cd $_

unzip ../function-source.zip

mkdir tests && touch tests/unit.http.test.js

cat > index.js <<EOF_CP
const {getFunction} = require('@google-cloud/functions-framework/testing');

describe('functions_convert_temperature_http', () => {
  // Sinon is a testing framework that is used to create mocks for Node.js applications written in Express.
  // Express is Node.js web application framework used to implement HTTP functions.
  const sinon = require('sinon');
  const assert = require('assert');
  require('../');

  const getMocks = () => {
    const req = {body: {}, query: {}};

    return {
      req: req,
      res: {
        send: sinon.stub().returnsThis(),
        status: sinon.stub().returnsThis()
      },
    };
  };

  let envOrig;
  before(() => {
    envOrig = JSON.stringify(process.env);
  });

  after(() => {
    process.env = JSON.parse(envOrig);
  });

  it('convertTemp: should convert a Fahrenheit temp value by default', () => {
    const mocks = getMocks();
    mocks.req.query = {temp: 70};

    const convertTemp = getFunction('convertTemp');
    convertTemp(mocks.req, mocks.res);
    assert.strictEqual(mocks.res.send.calledOnceWith('Temperature in Celsius is: 21.11.'), true);
  });

  it('convertTemp: should convert a Celsius temp value', () => {
    const mocks = getMocks();
    mocks.req.query = {temp: 21.11, convert: 'ctof'};

    const convertTemp = getFunction('convertTemp');
    convertTemp(mocks.req, mocks.res);
    assert.strictEqual(mocks.res.send.calledOnceWith('Temperature in Fahrenheit is: 70.00.'), true);
  });

  it('convertTemp: should convert a Celsius temp value by default', () => {
    process.env.TEMP_CONVERT_TO = 'ctof';
    const mocks = getMocks();
    mocks.req.query = {temp: 21.11};

    const convertTemp = getFunction('convertTemp');
    convertTemp(mocks.req, mocks.res);
    assert.strictEqual(mocks.res.send.calledOnceWith('Temperature in Fahrenheit is: 70.00.'), true);
  });

  it('convertTemp: should return an error message', () => {
    const mocks = getMocks();

    const convertTemp = getFunction('convertTemp');
    convertTemp(mocks.req, mocks.res);

    assert.strictEqual(mocks.res.status.calledOnce, true);
    assert.strictEqual(mocks.res.status.firstCall.args[0], 400);
  });
});
EOF_CP

cat > package.json <<EOF_CP
{
  "name": "temperature-converter",
  "version": "0.0.1",
  "main": "index.js",
  "scripts": {
    "unit-test": "mocha tests/unit*test.js --timeout=6000 --exit",
    "test": "npm -- run unit-test"
  },
  "devDependencies": {
    "mocha": "^9.0.0",
    "sinon": "^14.0.0"
  },
  "dependencies": {
    "@google-cloud/functions-framework": "^2.1.0"
  }
}
EOF_CP

mkdir tests && touch tests/unit.http.test.js

cat > tests/unit.http.test.js <<EOF_CP
const {getFunction} = require('@google-cloud/functions-framework/testing');

describe('functions_convert_temperature_http', () => {
  // Sinon is a testing framework that is used to create mocks for Node.js applications written in Express.
  // Express is Node.js web application framework used to implement HTTP functions.
  const sinon = require('sinon');
  const assert = require('assert');
  require('../');

  const getMocks = () => {
    const req = {body: {}, query: {}};

    return {
      req: req,
      res: {
        send: sinon.stub().returnsThis(),
        status: sinon.stub().returnsThis()
      },
    };
  };

  let envOrig;
  before(() => {
    envOrig = JSON.stringify(process.env);
  });

  after(() => {
    process.env = JSON.parse(envOrig);
  });

  it('convertTemp: should convert a Fahrenheit temp value by default', () => {
    const mocks = getMocks();
    mocks.req.query = {temp: 70};

    const convertTemp = getFunction('convertTemp');
    convertTemp(mocks.req, mocks.res);
    assert.strictEqual(mocks.res.send.calledOnceWith('Temperature in Celsius is: 21.11.'), true);
  });

  it('convertTemp: should convert a Celsius temp value', () => {
    const mocks = getMocks();
    mocks.req.query = {temp: 21.11, convert: 'ctof'};

    const convertTemp = getFunction('convertTemp');
    convertTemp(mocks.req, mocks.res);
    assert.strictEqual(mocks.res.send.calledOnceWith('Temperature in Fahrenheit is: 70.00.'), true);
  });

  it('convertTemp: should convert a Celsius temp value by default', () => {
    process.env.TEMP_CONVERT_TO = 'ctof';
    const mocks = getMocks();
    mocks.req.query = {temp: 21.11};

    const convertTemp = getFunction('convertTemp');
    convertTemp(mocks.req, mocks.res);
    assert.strictEqual(mocks.res.send.calledOnceWith('Temperature in Fahrenheit is: 70.00.'), true);
  });

  it('convertTemp: should return an error message', () => {
    const mocks = getMocks();

    const convertTemp = getFunction('convertTemp');
    convertTemp(mocks.req, mocks.res);

    assert.strictEqual(mocks.res.status.calledOnce, true);
    assert.strictEqual(mocks.res.status.firstCall.args[0], 400);
  });
});
EOF_CP

npm install

npm test

deploy_function() {
gcloud run deploy temperature-converter \
--image=$REGION-docker.pkg.dev/$PROJECT_ID/gcf-artifacts/temperature--converter:version_1 \
--set-env-vars=TEMP_CONVERT_TO=ctof \
--region=$REGION \
--project=$PROJECT_ID

gcloud run services update-traffic temperature-converter --to-latest --region=$REGION
}

deploy_success=false

while [ "$deploy_success" = false ]; do
    if deploy_function; then
        echo "Function deployed successfully..."
        deploy_success=true
    else
        echo "Retrying in 15 seconds..."
        sleep 15
    fi
done

curl -H "Authorization: bearer $(gcloud auth print-identity-token)" "${FUNCTION_URI}?temp=21.11"

echo "${BG_RED}${BOLD}Congratulations For Completing The Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#