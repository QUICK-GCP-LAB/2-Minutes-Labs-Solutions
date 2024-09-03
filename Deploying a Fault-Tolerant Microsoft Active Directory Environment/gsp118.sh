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

gcloud config set compute/region ${region1}

gcloud compute networks create ${vpc_name}  \
    --description "VPC network to deploy Active Directory" \
    --subnet-mode custom

gcloud compute networks subnets create private-ad-zone-1 \
    --network ${vpc_name} \
    --range 10.1.0.0/24 \
    --region ${region1}

gcloud compute networks subnets create private-ad-zone-2 \
    --network ${vpc_name} \
    --range 10.2.0.0/24 \
    --region ${region2}

gcloud compute firewall-rules create allow-internal-ports-private-ad \
    --network ${vpc_name} \
    --allow tcp:1-65535,udp:1-65535,icmp \
    --source-ranges  10.1.0.0/24,10.2.0.0/24

gcloud compute firewall-rules create allow-rdp \
    --network ${vpc_name} \
    --allow tcp:3389 \
    --source-ranges 0.0.0.0/0

gcloud compute instances create ad-dc1 --machine-type e2-standard-2 \
    --boot-disk-type pd-ssd \
    --boot-disk-size 50GB \
    --image-family windows-2016 --image-project windows-cloud \
    --network ${vpc_name} \
    --zone ${zone_1} --subnet private-ad-zone-1 \
    --private-network-ip=10.1.0.100

gcloud compute instances create ad-dc2 --machine-type e2-standard-2 \
    --boot-disk-size 50GB \
    --boot-disk-type pd-ssd \
    --image-family windows-2016 --image-project windows-cloud \
    --can-ip-forward \
    --network ${vpc_name} \
    --zone ${zone_2} \
    --subnet private-ad-zone-2 \
    --private-network-ip=10.2.0.100

echo "${BG_RED}${BOLD}Congratulations For Completing The Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#