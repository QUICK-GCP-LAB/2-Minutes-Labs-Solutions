cat > token_policies.txt <<EOF_END
[
  "default",
  "jenkins"
]
EOF_END


export PROJECT_ID=$(gcloud config get-value project)
gsutil cp token_policies.txt gs://$PROJECT_ID