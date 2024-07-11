# Develop GenAI Apps with Gemini and Streamlit: Challenge Lab || [GSP517](https://www.cloudskillsboost.google/focuses/87315?parent=catalog) ||

## Solution [here](https://youtu.be/DwOxKDyh1RU)

* Go to `USER-MANAGE NOTEBOOKS` from [here](https://console.cloud.google.com/vertex-ai/workbench/user-managed)

* Download `Jupyter` file from [here](https://github.com/QUICK-GCP-LAB/2-Minutes-Labs-Solutions/blob/main/Develop%20GenAI%20Apps%20with%20Gemini%20and%20Streamlit%20Challenge%20Lab/prompt.ipynb)

### Run the following Commands in CloudShell

### Assign Veriable

```
export REGION=
```

```
gcloud auth list

gcloud services enable run.googleapis.com

git clone https://github.com/GoogleCloudPlatform/generative-ai.git

cd generative-ai/gemini/sample-apps/gemini-streamlit-cloudrun

gsutil cp gs://spls/gsp517/chef.py .

rm -rf Dockerfile chef.py

wget https://raw.githubusercontent.com/QUICK-GCP-LAB/2-Minutes-Labs-Solutions/main/Develop%20GenAI%20Apps%20with%20Gemini%20and%20Streamlit%20Challenge%20Lab/Dockerfile.txt

wget https://raw.githubusercontent.com/QUICK-GCP-LAB/2-Minutes-Labs-Solutions/main/Develop%20GenAI%20Apps%20with%20Gemini%20and%20Streamlit%20Challenge%20Lab/chef.py

mv Dockerfile.txt Dockerfile

gcloud storage cp chef.py gs://$DEVSHELL_PROJECT_ID-generative-ai/

export PROJECT="$DEVSHELL_PROJECT_ID"


python3 -m venv gemini-streamlit
source gemini-streamlit/bin/activate
python3 -m  pip install -r requirements.txt


streamlit run chef.py \
  --browser.serverAddress=localhost \
  --server.enableCORS=false \
  --server.enableXsrfProtection=false \
  --server.port 8080
```

* Now Follow [Video's](https://youtu.be/DwOxKDyh1RU) Instructions

### Run again the following Commands in 

```
AR_REPO='chef-repo'
SERVICE_NAME='chef-streamlit-app' 
gcloud artifacts repositories create "$AR_REPO" --location="$REGION" --repository-format=Docker
gcloud builds submit --tag "$REGION-docker.pkg.dev/$PROJECT/$AR_REPO/$SERVICE_NAME"


gcloud run deploy "$SERVICE_NAME" \
  --port=8080 \
  --image="$REGION-docker.pkg.dev/$PROJECT/$AR_REPO/$SERVICE_NAME" \
  --allow-unauthenticated \
  --region=$REGION \
  --platform=managed  \
  --project=$PROJECT \
  --set-env-vars=GCP_PROJECT=$PROJECT,GCP_REGION=$REGION
```

### Congratulations 🎉 for completing the Lab !

##### *You Have Successfully Demonstrated Your Skills And Determination.*

#### *Well done!*

#### Don't Forget to Join the [Telegram Channel](https://t.me/quickgcplab) & [Discussion group](https://t.me/quickgcplabchats)

# [QUICK GCP LAB](https://www.youtube.com/@quickgcplab)
