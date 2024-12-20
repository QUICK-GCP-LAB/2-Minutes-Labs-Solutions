#!/bin/bash

# get apache ip
export APACHE_IP=$(gcloud compute instances describe linux-server-$DEVSHELL_PROJECT_ID --zone us-west1-b --format json | jq -r .networkInterfaces[0].accessConfigs[0].natIP)

# generate apache 200s
nohup watch curl http://$APACHE_IP/ &

# generate apache 404s
nohup watch curl http://$APACHE_IP/missing.html &

# generate apache 403s
nohup watch curl http://$APACHE_IP/secure.html &

# get load balancer ip
GKE_IP="null"
while [ $GKE_IP == "null" ]; do
  echo 'waiting for Load Balancer'
  export GKE_IP=$(gcloud compute forwarding-rules list --regions us-west1 --format json | jq -r .[0].IPAddress)
  sleep 5
done

# generate nginx 200s
nohup watch curl http://$GKE_IP/ &

# generate nginx 404s
nohup watch curl http://$GKE_IP/missing.html &

# generate pubsub activity
nohup watch -n 0.5 gcloud pubsub topics publish demo-topic --message "demo" &

sleep 3
echo 'Activity underway!'
