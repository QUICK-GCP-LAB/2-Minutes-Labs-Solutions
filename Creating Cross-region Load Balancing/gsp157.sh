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

export ZONE_1=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")

export REGION_1=$(echo "$ZONE_1" | cut -d '-' -f 1-2)
export REGION_2=$(echo "$ZONE_2" | cut -d '-' -f 1-2)

gcloud compute instances create www-1 \
    --image-family debian-11 \
    --image-project debian-cloud \
    --zone $ZONE_1 \
    --tags http-tag \
    --metadata startup-script="#! /bin/bash
      apt-get update
      apt-get install apache2 -y
      service apache2 restart
      Code
      EOF"

gcloud compute instances create www-2 \
    --image-family debian-11 \
    --image-project debian-cloud \
    --zone $ZONE_1 \
    --tags http-tag \
    --metadata startup-script="#! /bin/bash
      apt-get update
      apt-get install apache2 -y
      service apache2 restart
      Code
      EOF"

gcloud compute instances create www-3 \
    --image-family debian-11 \
    --image-project debian-cloud \
    --zone $ZONE_2 \
    --tags http-tag \
    --metadata startup-script="#! /bin/bash
      apt-get update
      apt-get install apache2 -y
      service apache2 restart
      Code
      EOF"

gcloud compute instances create www-4 \
    --image-family debian-11 \
    --image-project debian-cloud \
    --zone $ZONE_2 \
    --tags http-tag \
    --metadata startup-script="#! /bin/bash
      apt-get update
      apt-get install apache2 -y
      service apache2 restart
      Code
      EOF"

gcloud compute firewall-rules create www-firewall \
    --target-tags http-tag --allow tcp:80

gcloud compute instances list

gcloud compute addresses create lb-ip-cr \
    --ip-version=IPV4 \
    --global

gcloud compute instance-groups unmanaged create $REGION_1-resources-w --zone $ZONE_1

gcloud compute instance-groups unmanaged create $REGION_2-resources-w --zone $ZONE_2

gcloud compute instance-groups unmanaged add-instances $REGION_1-resources-w \
    --instances www-1,www-2 \
    --zone $ZONE_1

gcloud compute instance-groups unmanaged add-instances $REGION_2-resources-w \
    --instances www-3,www-4 \
    --zone $ZONE_2

gcloud compute health-checks create http http-basic-check

gcloud compute instance-groups unmanaged set-named-ports $REGION_1-resources-w \
    --named-ports http:80 \
    --zone $ZONE_1

gcloud compute instance-groups unmanaged set-named-ports $REGION_2-resources-w \
    --named-ports http:80 \
    --zone $ZONE_2

gcloud compute backend-services create web-map-backend-service \
    --protocol HTTP \
    --health-checks http-basic-check \
    --global

gcloud compute backend-services add-backend web-map-backend-service \
    --balancing-mode UTILIZATION \
    --max-utilization 0.8 \
    --capacity-scaler 1 \
    --instance-group $REGION_1-resources-w \
    --instance-group-zone $ZONE_1 \
    --global

gcloud compute backend-services add-backend web-map-backend-service \
    --balancing-mode UTILIZATION \
    --max-utilization 0.8 \
    --capacity-scaler 1 \
    --instance-group $REGION_2-resources-w \
    --instance-group-zone $ZONE_2 \
    --global

gcloud compute url-maps create web-map \
    --default-service web-map-backend-service

gcloud compute target-http-proxies create http-lb-proxy \
    --url-map web-map

LB_IP_ADDRESS=$(gcloud compute addresses list --format="get(ADDRESS)")

    gcloud compute forwarding-rules create http-cr-rule \
    --address $LB_IP_ADDRESS \
    --global \
    --target-http-proxy http-lb-proxy \
    --ports 80

echo "${BG_RED}${BOLD}Congratulations For Completing The Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#
