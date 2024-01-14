gsutil mb -l us -b on gs://$DEVSHELL_PROJECT_ID

echo "Awesome Lab Solution" > sample.txt

gsutil cp sample.txt gs://$DEVSHELL_PROJECT_ID

gcloud projects remove-iam-policy-binding $DEVSHELL_PROJECT_ID \
  --member=user:$USER_2 \
  --role=roles/viewer

gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
  --member=user:$USER_2 \
  --role=roles/storage.objectViewer