gcloud compute instances create bloghost --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --machine-type=e2-medium --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=default --metadata=startup-script=apt-get\ update$'\n'apt-get\ install\ apache2\ php\ php-mysql\ -y$'\n'service\ apache2\ restart,enable-oslogin=true --maintenance-policy=MIGRATE --provisioning-model=STANDARD --scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/trace.append --tags=http-server --create-disk=auto-delete=yes,boot=yes,device-name=bloghost,image=projects/debian-cloud/global/images/debian-11-bullseye-v20231212,mode=rw,size=10,type=projects/$DEVSHELL_PROJECT_ID/zones/$ZONE/diskTypes/pd-balanced --no-shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring --labels=goog-ec-src=vm_add-gcloud --reservation-affinity=any



export LOCATION=US

gcloud storage buckets create -l $LOCATION gs://$DEVSHELL_PROJECT_ID

gcloud storage cp gs://cloud-training/gcpfci/my-excellent-blog.png my-excellent-blog.png

gcloud storage cp my-excellent-blog.png gs://$DEVSHELL_PROJECT_ID/my-excellent-blog.png

gsutil acl ch -u allUsers:R gs://$DEVSHELL_PROJECT_ID/my-excellent-blog.png



gcloud sql instances create blog-db \
  --database-version=MYSQL_5_7 \
  --region="${ZONE%-*}" \
  --tier=db-n1-standard-1 \
  --storage-size=10GB \
  --storage-type=SSD \
  --backup-start-time=07:00 \
  --maintenance-window-day=MON \
  --maintenance-window-hour=10 \
  --backup-location="${ZONE%-*}"




gcloud sql instances describe blog-db --format="value(ipAddresses.ipAddress)"

gcloud sql users create blogdbuser --instance=blog-db 


# Define variables
INSTANCE_NAME="blog-db"
AUTHORIZED_NETWORK_NAME="web-front-end"
EXTERNAL=$(gcloud compute instances list --format='value(EXTERNAL_IP)')

# Patch the Cloud SQL instance with the authorized network
gcloud sql instances patch $INSTANCE_NAME \
  --authorized-networks=$EXTERNAL/32 \
  --quiet