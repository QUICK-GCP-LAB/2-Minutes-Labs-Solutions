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

export REGION="${ZONE%-*}"

gcloud compute networks create vpc-cluster --bgp-routing-mode=regional --subnet-mode=custom
gcloud compute networks subnets create cluster --network=vpc-cluster --range=192.168.110.0/24 --region=$REGION --enable-private-ip-google-access
gcloud compute networks create vpc-management --bgp-routing-mode=regional --subnet-mode=custom
gcloud compute networks subnets create management --network=vpc-management --range=192.168.120.0/24 --region=$REGION --enable-private-ip-google-access
gcloud compute networks create vpc-prod --bgp-routing-mode=regional --subnet-mode=custom
gcloud compute networks subnets create prod --network=vpc-prod --range=10.0.0.0/24 --region=$REGION
gcloud compute networks create vpc-qa --bgp-routing-mode=regional --subnet-mode=custom
gcloud compute networks subnets create qa --network=vpc-qa --range=10.0.1.0/24 --region=$REGION
gcloud compute firewall-rules create ingress-qa --action allow --direction=INGRESS --source-ranges=0.0.0.0/0 --network=vpc-qa --rules all
gcloud compute firewall-rules create ingress-prod --action allow --direction=INGRESS --source-ranges=0.0.0.0/0 --network=vpc-prod --rules all
gcloud compute firewall-rules create rdp-management --action allow --direction=INGRESS --source-ranges=0.0.0.0/0 --network=vpc-management --rules tcp:3389

gcloud compute instances create rdp-client --zone=$ZONE  --machine-type=n1-standard-4 --image-project=qwiklabs-resources --image=sap-rdp-image --network=vpc-management --subnet=management --tags=rdp,http-server,https-server --boot-disk-type=pd-ssd

gcloud compute instances create linux-qa --zone $ZONE --image-project=debian-cloud --image-family=debian-11 --custom-cpu 1 --custom-memory 4 --network-interface subnet=qa,private-network-ip=10.0.1.4,no-address --metadata startup-script="\#! /bin/bash
useradd -m -p sa1trmaMoZ25A cp
EOF"

gcloud compute instances create linux-prod --zone $ZONE --image-project=debian-cloud --image-family=debian-11 --custom-cpu 1 --custom-memory 4 --network-interface subnet=prod,private-network-ip=10.0.0.4,no-address --metadata startup-script="\#! /bin/bash
useradd -m -p sa1trmaMoZ25A cp
EOF"

echo "${BG_RED}${BOLD}Congratulations For Completing The Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#