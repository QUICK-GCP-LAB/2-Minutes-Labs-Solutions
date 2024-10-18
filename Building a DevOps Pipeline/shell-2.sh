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

cd ~/gcp-course/devops-repo
git add --all

git commit -am "Added Docker Support"

git push origin master

cat > cloudbuild.yaml <<'EOF_END'
steps:
  - name: 'gcr.io/cloud-builders/docker'
    args: ['build', '-t', '$REGION-docker.pkg.dev/$DEVSHELL_PROJECT_ID/devops-repo/devops-image:$COMMIT_SHA', '.']
images:
  - '$REGION-docker.pkg.dev/$DEVSHELL_PROJECT_ID/devops-repo/devops-image:$COMMIT_SHA'
options:
  logging: CLOUD_LOGGING_ONLY
EOF_END

gcloud builds triggers create cloud-source-repositories \
    --name="devops-trigger" \
    --service-account="projects/$DEVSHELL_PROJECT_ID/serviceAccounts/$DEVSHELL_PROJECT_ID@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com"  \
    --description="Awesome" \
    --repo="devops-repo" \
    --branch-pattern=".*" \
    --build-config="cloudbuild.yaml"

cat > main.py <<'EOF_END'
from flask import Flask, render_template, request

app = Flask(__name__)

@app.route("/")
def main():
    model = {"title": "Hello Build Trigger."}
    return render_template('index.html', model=model)

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=8080, debug=True, threaded=True)
EOF_END

cd ~/gcp-course/devops-repo
git commit -a -m "Testing Build Trigger"

git push origin master

export IMAGE=$(gcloud artifacts docker images describe \
    $REGION-docker.pkg.dev/$DEVSHELL_PROJECT_ID/devops-repo/devops-image:v0.1 \
    --format 'value(image_summary.digest)')

echo "${CYAN}${BOLD}Click here: "${RESET}""${BLUE}${BOLD}""https://console.cloud.google.com/compute/instancesAdd?project=$DEVSHELL_PROJECT_ID"""${RESET}"

echo "${YELLOW}${BOLD}Copy this: "${RESET}""${GREEN}${BOLD}""$REGION-docker.pkg.dev/$DEVSHELL_PROJECT_ID/devops-repo/devops-image@$IMAGE"""${RESET}"

echo "${YELLOW}${BOLD}NOW${RESET}" "${WHITE}${BOLD}FOLLOW${RESET}" "${MAGENTA}${BOLD}VIDEO'S INSTRUCTIONS${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#
