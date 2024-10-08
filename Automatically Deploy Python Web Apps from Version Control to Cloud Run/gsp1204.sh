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

gcloud services enable \
    cloudbuild.googleapis.com \
    run.googleapis.com

cd ~

mkdir helloworld

cd helloworld

cat > requirements.txt << "EOF"
Flask==3.0.0
gunicorn==20.1.0
EOF

touch main.py

cat > main.py <<EOF_END
import os

from flask import Flask

app = Flask(__name__)

app_version = "0.0.0"

@app.route("/")
def hello_world():
    return f"Hello! This is version {app_version} of my application."


if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=int(os.environ.get("PORT", 8080)))
EOF_END

cd ~/helloworld

git init -b main

curl -sS https://webi.sh/gh | sh

gh auth login

gh api user -q ".login"

GITHUB_USERNAME=$(gh api user -q ".login")

echo ${GITHUB_USERNAME}

git config --global user.name "${GITHUB_USERNAME}"
git config --global user.email "${USER_EMAIL}"

git add .

git commit -m "initial commit"

cd ~/helloworld

gh repo create hello-world --private

git remote add origin \
https://github.com/${GITHUB_USERNAME}/hello-world

git push -u origin main

echo -e "\n\nTo see your code, visit this URL:\n \
https://github.com/${GITHUB_USERNAME}/hello-world/blob/main/main.py \n\n"

echo "${YELLOW}${BOLD}NOW${RESET}" "${WHITE}${BOLD}FOLLOW${RESET}" "${GREEN}${BOLD}VIDEO'S INSTRUCTIONS${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#