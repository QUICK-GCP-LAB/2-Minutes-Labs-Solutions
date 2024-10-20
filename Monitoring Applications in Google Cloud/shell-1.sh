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

DEVSHELL_PROJECT_ID=$(gcloud config get-value project)
TOKEN=$(gcloud auth application-default print-access-token)

mkdir gcp-logging
cd gcp-logging

git clone https://GitHub.com/GoogleCloudPlatform/training-data-analyst.git

cd training-data-analyst/courses/design-process/deploying-apps-to-gcp

cat > main.py <<'EOF_END'
from flask import Flask, render_template, request
import googlecloudprofiler

app = Flask(__name__)


@app.route("/")
def main():
    model = {"title": "Hello GCP."}
    return render_template('index.html', model=model)

try:
    googlecloudprofiler.start(verbose=3)
except (ValueError, NotImplementedError) as exc:
    print(exc)

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=8080, debug=True, threaded=True)
EOF_END

cat > requirements.txt <<'EOF_END'
Flask==2.0.3
itsdangerous==2.0.1
Jinja2==3.0.3
werkzeug==2.2.2
google-cloud-profiler==3.0.6
protobuf==3.20.1
EOF_END

gcloud services enable cloudprofiler.googleapis.com

docker build -t test-python .

cat > app.yaml <<'EOF_END'
runtime: python39
EOF_END

gcloud app create --region=$REGION

gcloud app deploy --version=one --quiet

gcloud compute instances create quickgcplab \
    --zone=us-south1-b \
    --machine-type=e2-medium

echo "${CYAN}${BOLD}Click here: "${RESET}""${BLUE}${BOLD}""https://console.cloud.google.com/monitoring/uptime/create?project=$DEVSHELL_PROJECT_ID"""${RESET}"

echo "${YELLOW}${BOLD}Copy this: "${RESET}""${GREEN}${BOLD}""$DEVSHELL_PROJECT_ID.appspot.com"""${RESET}"

echo "${YELLOW}${BOLD}NOW${RESET}" "${WHITE}${BOLD}FOLLOW${RESET}" "${GREEN}${BOLD}VIDEO'S INSTRUCTIONS${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#