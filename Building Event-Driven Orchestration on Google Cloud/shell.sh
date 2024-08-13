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
  workflows.googleapis.com \
  workflowexecutions.googleapis.com \
  eventarc.googleapis.com \
  tasks.googleapis.com \
  cloudscheduler.googleapis.com \
  storage.googleapis.com \
  vision.googleapis.com \
  run.googleapis.com \
  cloudfunctions.googleapis.com \
  firestore.googleapis.com \
  appengine.googleapis.com \
  cloudbuild.googleapis.com \
  artifactregistry.googleapis.com

sleep 10

export UPLOAD_BUCKET=uploaded-images-${GOOGLE_CLOUD_PROJECT}
gcloud storage buckets create \
  --location=$REGION gs://${UPLOAD_BUCKET}
gcloud storage buckets update \
  gs://${UPLOAD_BUCKET} --uniform-bucket-level-access
gcloud storage buckets add-iam-policy-binding \
  gs://${UPLOAD_BUCKET} \
  --member=allUsers --role=roles/storage.objectViewer

export GENERATED_BUCKET=generated-images-${GOOGLE_CLOUD_PROJECT}
gcloud storage buckets create \
 --location=$REGION gs://${GENERATED_BUCKET}
gcloud storage buckets update \
  gs://${GENERATED_BUCKET} --uniform-bucket-level-access
gcloud storage buckets add-iam-policy-binding \
  gs://${GENERATED_BUCKET} \
  --member=allUsers --role=roles/storage.objectViewer

export FIRESTORE_LOCATION=$REGION
gcloud firestore databases create \
  --location=${FIRESTORE_LOCATION} \
  --type=firestore-native

gcloud firestore indexes composite create \
  --collection-group=images \
  --field-config field-path=thumbnail,order=descending \
  --field-config field-path=created,order=descending \
  --async

export QUEUE_REGION=$REGION
gcloud tasks queues create thumbnail-task-queue \
  --location=${QUEUE_REGION}

git clone --depth=1 https://github.com/GoogleCloudPlatform/training-data-analyst

ln -s ~/training-data-analyst/courses/orchestration-and-choreography/lab1 ~/code

export REPO_NAME=image-app-repo
export REPO_REGION=$REGION
gcloud artifacts repositories create ${REPO_NAME} \
  --location=${REPO_REGION} --repository-format=docker

export REPO_NAME=image-app-repo
export REPO_REGION=$REGION
export THUMBNAIL_SERVICE_NAME=create-thumbnail
cd ~/code/cloud-run/create-thumbnail
gcloud builds submit \
  . \
  --tag ${REPO_REGION}-docker.pkg.dev/${GOOGLE_CLOUD_PROJECT}/${REPO_NAME}/${THUMBNAIL_SERVICE_NAME}

deploy_function() {
    export REPO_NAME=image-app-repo
    export REPO_REGION=$REGION
    export THUMBNAIL_SERVICE_REGION=$REGION
    export THUMBNAIL_SERVICE_NAME=create-thumbnail
    export GENERATED_IMAGES_BUCKET=generated-images-${GOOGLE_CLOUD_PROJECT}
    cd ~/code/cloud-run/create-thumbnail
    gcloud config set run/region ${THUMBNAIL_SERVICE_REGION}
    gcloud config set run/platform managed
    gcloud run deploy ${THUMBNAIL_SERVICE_NAME} \
        --image ${REPO_REGION}-docker.pkg.dev/${GOOGLE_CLOUD_PROJECT}/${REPO_NAME}/${THUMBNAIL_SERVICE_NAME} \
        --no-allow-unauthenticated \
        --memory=1Gi \
        --max-instances=1 \
        --update-env-vars GENERATED_IMAGES_BUCKET=${GENERATED_IMAGES_BUCKET}
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

deploy_function() {
    export REPO_NAME=image-app-repo
    export REPO_REGION=$REGION
    export COLLAGE_SERVICE_REGION=$REGION
    export COLLAGE_SERVICE_NAME=create-collage
    export GENERATED_IMAGES_BUCKET=generated-images-${GOOGLE_CLOUD_PROJECT}

    cd ~/code/cloud-run/create-collage

    gcloud builds submit \
        . \
        --tag ${REPO_REGION}-docker.pkg.dev/${GOOGLE_CLOUD_PROJECT}/${REPO_NAME}/${COLLAGE_SERVICE_NAME}

    gcloud config set run/region ${COLLAGE_SERVICE_REGION}
    gcloud config set run/platform managed

    gcloud run deploy ${COLLAGE_SERVICE_NAME} \
        --image ${REPO_REGION}-docker.pkg.dev/${GOOGLE_CLOUD_PROJECT}/${REPO_NAME}/${COLLAGE_SERVICE_NAME} \
        --no-allow-unauthenticated \
        --memory=1Gi \
        --max-instances=1 \
        --update-env-vars GENERATED_IMAGES_BUCKET=${GENERATED_IMAGES_BUCKET}
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

export DELETE_SERVICE_REGION=$REGION
export DELETE_SERVICE_NAME=delete-image
export GENERATED_IMAGES_BUCKET=generated-images-${GOOGLE_CLOUD_PROJECT}
cd ~/code/cloud-run/delete-image
gcloud config set run/region ${DELETE_SERVICE_REGION}
gcloud config set run/platform managed
gcloud run deploy ${DELETE_SERVICE_NAME} \
  --source . \
  --no-allow-unauthenticated \
  --max-instances=1 \
  --update-env-vars GENERATED_IMAGES_BUCKET=${GENERATED_IMAGES_BUCKET} --quiet

deploy_function() {
    export EXTRACT_FUNCTION_REGION=$REGION
    export EXTRACT_FUNCTION_NAME=extract-image-metadata
    cd ~/code/cloud-functions/${EXTRACT_FUNCTION_NAME} || return 1
    gcloud config set functions/region ${EXTRACT_FUNCTION_REGION} || return 1
    gcloud functions deploy ${EXTRACT_FUNCTION_NAME} \
      --source . \
      --runtime=nodejs18 \
      --entry-point=extract_image_metadata \
      --trigger-http \
      --no-allow-unauthenticated
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

export WORKFLOWS_SA=workflows-sa
gcloud iam service-accounts create ${WORKFLOWS_SA}
gcloud projects add-iam-policy-binding ${GOOGLE_CLOUD_PROJECT} \
  --member="serviceAccount:${WORKFLOWS_SA}@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com" \
  --role="roles/datastore.user"
gcloud projects add-iam-policy-binding ${GOOGLE_CLOUD_PROJECT} \
  --member="serviceAccount:${WORKFLOWS_SA}@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com" \
  --role="roles/cloudtasks.enqueuer"
gcloud projects add-iam-policy-binding ${GOOGLE_CLOUD_PROJECT} \
  --member="serviceAccount:${WORKFLOWS_SA}@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com" \
  --role="roles/logging.logWriter"
gcloud projects add-iam-policy-binding ${GOOGLE_CLOUD_PROJECT} \
  --member="serviceAccount:${WORKFLOWS_SA}@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com" \
  --role="roles/iam.serviceAccountUser"

export WORKFLOWS_SA=workflows-sa
export THUMBNAIL_SERVICE_NAME=create-thumbnail
export THUMBNAIL_SERVICE_REGION=$REGION
export EXTRACT_FUNCTION_NAME=extract-image-metadata
gcloud functions add-iam-policy-binding ${EXTRACT_FUNCTION_NAME} \
  --member="serviceAccount:${WORKFLOWS_SA}@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com" \
  --role="roles/cloudfunctions.invoker"
gcloud run services add-iam-policy-binding ${THUMBNAIL_SERVICE_NAME} \
  --region=${THUMBNAIL_SERVICE_REGION} \
  --member="serviceAccount:${WORKFLOWS_SA}@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com" \
  --role="roles/run.viewer"
gcloud run services add-iam-policy-binding ${THUMBNAIL_SERVICE_NAME} \
  --region=${THUMBNAIL_SERVICE_REGION} \
  --member="serviceAccount:${WORKFLOWS_SA}@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com" \
  --role="roles/run.invoker"

export WORKFLOW_NAME=image-add-workflow
export WORKFLOW_REGION=$REGION
export WORKFLOWS_SA=workflows-sa
cd ~/code/workflows
gcloud workflows deploy ${WORKFLOW_NAME} \
  --source=${WORKFLOW_NAME}.yaml \
  --location=${WORKFLOW_REGION} \
  --service-account="${WORKFLOWS_SA}@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com"

export WORKFLOW_TRIGGER_SA=workflow-trigger-sa
gcloud iam service-accounts create ${WORKFLOW_TRIGGER_SA}
gcloud projects add-iam-policy-binding ${GOOGLE_CLOUD_PROJECT} \
  --member="serviceAccount:${WORKFLOW_TRIGGER_SA}@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com" \
  --role="roles/workflows.invoker"
gcloud projects add-iam-policy-binding ${GOOGLE_CLOUD_PROJECT} \
  --member "serviceAccount:${WORKFLOW_TRIGGER_SA}@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com" \
  --role="roles/eventarc.eventReceiver"

export CLOUD_STORAGE_SA="$(gcloud storage service-agent)"
gcloud projects add-iam-policy-binding ${GOOGLE_CLOUD_PROJECT} \
  --member="serviceAccount:${CLOUD_STORAGE_SA}" \
  --role="roles/pubsub.publisher"

deploy_function() {
    export WORKFLOW_TRIGGER_REGION=$REGION
    export WORKFLOW_NAME=image-add-workflow
    export WORKFLOW_REGION=$REGION
    export UPLOAD_BUCKET=uploaded-images-${GOOGLE_CLOUD_PROJECT}
    export WORKFLOW_TRIGGER_SA=workflow-trigger-sa
    gcloud eventarc triggers create image-add-trigger \
      --location=${WORKFLOW_TRIGGER_REGION} \
      --destination-workflow=${WORKFLOW_NAME} \
      --destination-workflow-location=${WORKFLOW_REGION} \
      --event-filters="type=google.cloud.storage.object.v1.finalized" \
      --event-filters="bucket=${UPLOAD_BUCKET}" \
      --service-account="${WORKFLOW_TRIGGER_SA}@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com"
}

deploy_success=false

while [ "$deploy_success" = false ]; do
    if deploy_function; then
        echo "Function deployed successfully..."
        deploy_success=true
    else
        echo "Deployment failed. Retrying in 15 seconds..."
        sleep 15
    fi
done

export UPLOAD_BUCKET=uploaded-images-${GOOGLE_CLOUD_PROJECT}
export IMAGE_NAME=neon.jpg
gcloud storage cp ~/code/images/${IMAGE_NAME} gs://${UPLOAD_BUCKET}

export UPLOAD_BUCKET=uploaded-images-${GOOGLE_CLOUD_PROJECT}
export GENERATED_BUCKET=generated-images-${GOOGLE_CLOUD_PROJECT}
export IMAGE_NAME=neon.jpg
echo "uploaded image: https://storage.googleapis.com/${UPLOAD_BUCKET}/${IMAGE_NAME}"
echo "generated image: https://storage.googleapis.com/${GENERATED_BUCKET}/${IMAGE_NAME}"
echo "Listing of generated-images bucket:"
gcloud storage ls gs://${GENERATED_BUCKET}

export UPLOAD_BUCKET=uploaded-images-${GOOGLE_CLOUD_PROJECT}
gcloud storage cp ~/code/images/alley.jpg \
  gs://${UPLOAD_BUCKET}
gcloud storage cp ~/code/images/desktop.jpg \
  gs://${UPLOAD_BUCKET}
gcloud storage cp ~/code/images/rainbow.jpg \
  gs://${UPLOAD_BUCKET}
gcloud storage cp ~/code/images/vegas.jpg \
  gs://${UPLOAD_BUCKET}

export COLLAGE_SCHED_SA=collage-schedule-sa
export COLLAGE_SERVICE=create-collage
export COLLAGE_SERVICE_REGION=$REGION
gcloud iam service-accounts create ${COLLAGE_SCHED_SA}
gcloud run services add-iam-policy-binding ${COLLAGE_SERVICE} \
  --region=${COLLAGE_SERVICE_REGION} \
  --member="serviceAccount:${COLLAGE_SCHED_SA}@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com" \
  --role="roles/run.invoker"

export SERVICE_REGION=$REGION
export SERVICE_NAME=create-collage
export URL=$(gcloud run services describe ${SERVICE_NAME} \
  --platform managed \
  --region ${SERVICE_REGION} \
  --format 'value(status.url)')

job_function() {
    gcloud scheduler jobs create http collage-schedule \
      --location="$REGION" \
      --schedule="* * * * *" \
      --time-zone="UTC" \
      --http-method=POST \
      --uri="$URL" \
      --oidc-service-account-email="collage-schedule-sa@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com" \
      --oidc-token-audience="$URL"
}

deploy_success=false

while [ "$deploy_success" = false ]; do
    if job_function; then
        echo "Function deployed successfully..."
        deploy_success=true
    else
        echo "Retrying in 15 seconds..."
        sleep 15
    fi
done

export GENERATED_BUCKET=generated-images-${GOOGLE_CLOUD_PROJECT}
export IMAGE_NAME=collage.png
echo "generated collage: https://storage.googleapis.com/${GENERATED_BUCKET}/${IMAGE_NAME}"
echo "Listing of generated-images bucket:"
gcloud storage ls gs://${GENERATED_BUCKET}

export DELETE_TRIGGER_SA=delete-image-trigger-sa
export DELETE_SERVICE_REGION=$REGION
export DELETE_SERVICE=delete-image
gcloud iam service-accounts create ${DELETE_TRIGGER_SA}
gcloud projects add-iam-policy-binding ${GOOGLE_CLOUD_PROJECT} \
  --member "serviceAccount:${DELETE_TRIGGER_SA}@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com" \
  --role="roles/eventarc.eventReceiver"
gcloud run services add-iam-policy-binding ${DELETE_SERVICE} \
  --region=${DELETE_SERVICE_REGION} \
  --member="serviceAccount:${DELETE_TRIGGER_SA}@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com" \
  --role="roles/run.invoker"

gcloud eventarc triggers create image-delete-trigger \
--location=$REGION \
--service-account=delete-image-trigger-sa@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com \
--destination-run-service=delete-image \
--destination-run-region=$REGION \
--destination-run-path="/" \
--event-filters="bucket=uploaded-images-$GOOGLE_CLOUD_PROJECT" \
--event-filters="type=google.cloud.storage.object.v1.deleted"

gcloud firestore indexes composite create \
  --collection-group=images \
  --field-config field-path=thumbnail,order=descending \
  --field-config field-path=created,order=descending \
  --async

echo "${BG_RED}${BOLD}Congratulations For Completing The Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#