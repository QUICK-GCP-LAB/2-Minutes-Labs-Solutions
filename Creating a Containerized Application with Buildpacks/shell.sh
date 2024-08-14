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

gcloud config set compute/region $REGION

gcloud services enable artifactregistry.googleapis.com run.googleapis.com translate.googleapis.com

mkdir app && cd app

gsutil cp gs://cloud-training/CBL513/sample-apps/sample-py-app.zip . && unzip sample-py-app

ls sample-py-app

cd sample-py-app

pack build --builder=gcr.io/buildpacks/builder sample-py-app

docker images

docker run -it -e PORT=8080 -p 8080:8080 -d sample-py-app

cat > main.py <<'EOF_END'
from flask import Flask, request
import google.auth
from google.cloud import translate

app = Flask(__name__)
_, PROJECT_ID = google.auth.default()
TRANSLATE = translate.TranslationServiceClient()
PARENT = 'projects/{}'.format(PROJECT_ID)
SOURCE, TARGET = ('en', 'English'), ('es', 'Spanish')

@app.route('/', methods=['GET', 'POST'])
def index():
    # reset all variables
    text = translated = None

    if request.method == 'POST':
        text = request.get_json().get('text').strip()
        if text:
            data = {
                'contents': [text],
                'parent': PARENT,
                'target_language_code': TARGET[0],
            }
            # handle older call for backwards-compatibility
            try:
                rsp = TRANSLATE.translate_text(request=data)
            except TypeError:
                rsp = TRANSLATE.translate_text(**data)
            translated = rsp.translations[0].translated_text

    # create context
    context = {
        'trtext': translated
    }
    return context

if __name__ == "__main__":
    # Dev only: run "python main.py" and open http://localhost:8080
    import os
    app.run(host="localhost", port=int(os.environ.get('PORT', 8080)), debug=True)
EOF_END

gcloud run deploy sample-py-app --source . --region=${REGION} --allow-unauthenticated --quiet

SERVICE_URL=$(gcloud run services list --format='value(URL)')

curl $SERVICE_URL -H 'Content-Type: application/json' -d '{"text" : "Welcome to this sample app, built with Google Cloud buildpacks."}'

echo "${BG_RED}${BOLD}Congratulations For Completing The Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#