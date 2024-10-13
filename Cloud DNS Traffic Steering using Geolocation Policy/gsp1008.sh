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

gcloud services enable compute.googleapis.com
gcloud services enable dns.googleapis.com
gcloud services list | grep -E 'compute|dns'

gcloud compute firewall-rules create fw-default-iapproxy \
--direction=INGRESS \
--priority=1000 \
--network=default \
--action=ALLOW \
--rules=tcp:22,icmp \
--source-ranges=35.235.240.0/20

gcloud compute firewall-rules create allow-http-traffic --direction=INGRESS --priority=1000 --network=default --action=ALLOW --rules=tcp:80 --source-ranges=0.0.0.0/0 --target-tags=http-server

gcloud compute instances create us-client-vm --machine-type e2-medium --zone $ZONE_1

gcloud compute instances create europe-client-vm --machine-type e2-medium --zone $ZONE_2

gcloud compute instances create asia-client-vm --machine-type e2-medium --zone $ZONE_3

gcloud compute instances create us-web-vm \
--zone=$ZONE_1 \
--machine-type=e2-medium \
--network=default \
--subnet=default \
--tags=http-server \
--metadata=startup-script='#! /bin/bash
 apt-get update
 apt-get install apache2 -y
 echo "Page served from: us-west1" | \
 tee /var/www/html/index.html
 systemctl restart apache2'

gcloud compute instances create europe-web-vm \
--zone=$ZONE_2 \
--machine-type=e2-medium \
--network=default \
--subnet=default \
--tags=http-server \
--metadata=startup-script='#! /bin/bash
 apt-get update
 apt-get install apache2 -y
 echo "Page served from: europe-west1" | \
 tee /var/www/html/index.html
 systemctl restart apache2'

export US_WEB_IP=$(gcloud compute instances describe us-web-vm --zone=$ZONE_1 --format="value(networkInterfaces.networkIP)")

export EUROPE_WEB_IP=$(gcloud compute instances describe europe-web-vm --zone=$ZONE_2 --format="value(networkInterfaces.networkIP)")

gcloud dns managed-zones create example --description=test --dns-name=example.com --networks=default --visibility=private

gcloud beta dns record-sets create geo.example.com \
--ttl=5 --type=A --zone=example \
--routing_policy_type=GEO \
--routing_policy_data="us-west1=$US_WEB_IP;europe-west1=$EUROPE_WEB_IP"

gcloud beta dns record-sets list --zone=example

echo "${BG_RED}${BOLD}Congratulations For Completing The Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#