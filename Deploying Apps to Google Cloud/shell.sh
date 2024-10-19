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

gcloud services enable run.googleapis.com

export PROJECT_ID=$(gcloud config get-value project)

export PROJECT_NUMBER=$(gcloud projects describe ${PROJECT_ID} \
    --format="value(projectNumber)")

mkdir gcp-course

cd gcp-course

git clone https://GitHub.com/GoogleCloudPlatform/training-data-analyst.git

cd training-data-analyst/courses/design-process/deploying-apps-to-gcp

docker build -t test-python .

cat > app.yaml <<'EOF_END'
runtime: python39
EOF_END

gcloud app create --region=$REGION

gcloud app deploy --version=one --quiet

cat > main.py <<'EOF_END'
from flask import Flask, render_template, request

app = Flask(__name__)


@app.route("/")
def main():
    model = {"title": "Hello App Engine"}
    return render_template('index.html', model=model)


if __name__ == "__main__":
    app.run(host='0.0.0.0', port=8080, debug=True, threaded=True)
EOF_END

gcloud app deploy --version=two --no-promote --quiet

sleep 30

gcloud app services set-traffic default --splits=two=1 --quiet

gcloud beta container --project "$DEVSHELL_PROJECT_ID" clusters create-auto "autopilot-cluster-1" \
  --region "$REGION" \
  --release-channel "regular" \
  --network "projects/$DEVSHELL_PROJECT_ID/global/networks/default" \
  --subnetwork "projects/$DEVSHELL_PROJECT_ID/regions/$REGION/subnetworks/default" \
  --cluster-ipv4-cidr "/17" \
  --binauthz-evaluation-mode=DISABLED

gcloud container clusters get-credentials autopilot-cluster-1 \
  --region $REGION \
  --project $DEVSHELL_PROJECT_ID

kubectl get nodes

cat > main.py <<'EOF_END'
from flask import Flask, render_template, request

app = Flask(__name__)


@app.route("/")
def main():
    model = {"title": "Hello Kubernetes Engine"}
    return render_template('index.html', model=model)


if __name__ == "__main__":
    app.run(host='0.0.0.0', port=8080, debug=True, threaded=True)
EOF_END

cat > kubernetes-config.yaml <<'EOF_END'
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: devops-deployment
  labels:
    app: devops
    tier: frontend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: devops
      tier: frontend
  template:
    metadata:
      labels:
        app: devops
        tier: frontend
    spec:
      containers:
      - name: devops-demo
        image: <YOUR IMAGE PATH HERE>
        ports:
        - containerPort: 8080

---
apiVersion: v1
kind: Service
metadata:
  name: devops-deployment-lb
  labels:
    app: devops
    tier: frontend-lb
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 8080
  selector:
    app: devops
    tier: frontend
EOF_END

gcloud artifacts repositories create devops-demo \
    --repository-format=docker \
    --location=$REGION

gcloud auth configure-docker $REGION-docker.pkg.dev

gcloud builds submit --tag $REGION-docker.pkg.dev/$DEVSHELL_PROJECT_ID/devops-demo/devops-image:v0.2 .

CONTAINER_PATH=$REGION-docker.pkg.dev/$DEVSHELL_PROJECT_ID/devops-demo/devops-image:v0.2

cat > kubernetes-config.yaml << EOM
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: devops-deployment
  labels:
    app: devops
    tier: frontend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: devops
      tier: frontend
  template:
    metadata:
      labels:
        app: devops
        tier: frontend
    spec:
      containers:
      - name: devops-demo
        image: ${CONTAINER_PATH}
        ports:
        - containerPort: 8080

---
apiVersion: v1
kind: Service
metadata:
  name: devops-deployment-lb
  labels:
    app: devops
    tier: frontend-lb
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 8080
  selector:
    app: devops
    tier: frontend
EOM

kubectl apply -f kubernetes-config.yaml

kubectl get pods

sleep 150

kubectl get pods

kubectl get services

cat > main.py <<'EOF_END'
from flask import Flask, render_template, request

app = Flask(__name__)


@app.route("/")
def main():
    model = {"title": "Hello Cloud Run"}
    return render_template('index.html', model=model)


if __name__ == "__main__":
    app.run(host='0.0.0.0', port=8080, debug=True, threaded=True)
EOF_END

gcloud builds submit --tag $REGION-docker.pkg.dev/$DEVSHELL_PROJECT_ID/devops-demo/cloud-run-image:v0.1 .

export IMAGE=$(gcloud artifacts docker images describe \
    $REGION-docker.pkg.dev/$DEVSHELL_PROJECT_ID/devops-demo/cloud-run-image:v0.1 \
    --format 'value(image_summary.digest)')

gcloud run deploy hello-cloud-run \
  --image=$REGION-docker.pkg.dev/$DEVSHELL_PROJECT_ID/devops-demo/cloud-run-image@$IMAGE \
  --allow-unauthenticated \
  --port=8080 \
  --service-account=$PROJECT_NUMBER-compute@developer.gserviceaccount.com \
  --max-instances=6 \
  --region=$REGION

echo "${BG_RED}${BOLD}Congratulations For Completing The Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#
