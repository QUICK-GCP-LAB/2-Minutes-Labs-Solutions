gcloud builds submit \
  --tag gcr.io/$GOOGLE_CLOUD_PROJECT/email-service

gcloud run deploy email-service \
  --image gcr.io/$GOOGLE_CLOUD_PROJECT/email-service \
  --platform managed \
  --region $REGION \
  --no-allow-unauthenticated \
  --max-instances=1