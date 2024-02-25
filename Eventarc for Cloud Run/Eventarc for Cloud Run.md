# Eventarc for Cloud Run || [GSP773](https://www.cloudskillsboost.google/focuses/15657?parent=catalog) ||

## Solution [here]()

### Run the following Commands in CloudShell
```
export REGION=
```
```
gcloud config set project $DEVSHELL_PROJECT_ID

gcloud config set run/region $REGION

gcloud config set run/platform managed

gcloud config set eventarc/location $REGION

export PROJECT_NUMBER="$(gcloud projects list \
  --filter=$(gcloud config get-value project) \
  --format='value(PROJECT_NUMBER)')"

gcloud projects add-iam-policy-binding $(gcloud config get-value project) \
  --member=serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com \
  --role='roles/eventarc.admin'

export SERVICE_NAME=event-display

export IMAGE_NAME="gcr.io/cloudrun/hello"

gcloud run deploy ${SERVICE_NAME} \
  --image ${IMAGE_NAME} \
  --allow-unauthenticated \
  --max-instances=3

gcloud beta eventarc attributes types describe \
  google.cloud.pubsub.topic.v1.messagePublished

gcloud beta eventarc triggers create trigger-pubsub \
  --destination-run-service=${SERVICE_NAME} \
  --matching-criteria="type=google.cloud.pubsub.topic.v1.messagePublished"

export TOPIC_ID=$(gcloud eventarc triggers describe trigger-pubsub \
  --format='value(transport.pubsub.topic)')

gcloud pubsub topics publish ${TOPIC_ID} --message="Hello there"

export BUCKET_NAME=$(gcloud config get-value project)-cr-bucket

gsutil mb -p $(gcloud config get-value project) \
  -l $(gcloud config get-value run/region) \
  gs://${BUCKET_NAME}/

echo "Hello World" > random.txt

gsutil cp random.txt gs://${BUCKET_NAME}/random.txt
```

### Enable Audit Logs

1. From the Navigation menu, select `IAM & Admin` > `Audit Logs`.

2. In the list of services, check the box for `Google Cloud Storage`.

3. On the right hand side, click the `LOG TYPE` tab. `Admin Write` is selected by default, make sure you also select `Admin Read`, `Data Read`, `Data Write` and then click `Save`.

### Again Run the following Commands in CloudShell

```
gcloud eventarc triggers delete trigger-pubsub

gcloud beta eventarc attributes types describe google.cloud.audit.log.v1.written

gcloud beta eventarc triggers create trigger-auditlog \
--destination-run-service=${SERVICE_NAME} \
--matching-criteria="type=google.cloud.audit.log.v1.written" \
--matching-criteria="serviceName=storage.googleapis.com" \
--matching-criteria="methodName=storage.objects.create" \
--service-account=${PROJECT_NUMBER}-compute@developer.gserviceaccount.com

gsutil cp random.txt gs://${BUCKET_NAME}/random.txt
```

### Congratulations 🎉 for Completing the Lab !

##### *You Have Successfully Demonstrated Your Skills And Determination.*

#### *Well done!*

#### Don't Forget to Join the [Telegram Channel](https://t.me/QuickGcpLab) & [Discussion group](https://t.me/QuickGcpLabChats)

# [QUICK GCP LAB](https://www.youtube.com/@quickgcplab)