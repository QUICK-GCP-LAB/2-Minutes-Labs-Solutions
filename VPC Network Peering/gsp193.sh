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

echo "${YELLOW}${BOLD}Starting${RESET}" "${GREEN}${BOLD}Execution${RESET}"

export PROJECT_ID=$DEVSHELL_PROJECT_ID

export REGION_1="${ZONE%-*}"

export REGION_2="${ZONE_2%-*}"

gcloud config set project $PROJECT_ID

gcloud compute networks create network-a --subnet-mode custom

gcloud compute networks subnets create network-a-subnet --network network-a \
    --range 10.0.0.0/16 --region $REGION_1

gcloud compute instances create vm-a --zone $ZONE --network network-a --subnet network-a-subnet --machine-type e2-small

gcloud compute firewall-rules create network-a-fw --network network-a --allow tcp:22,icmp

# Switch to the second project
gcloud config set project $PROJECT_ID_2

# Create the custom network
gcloud compute networks create network-b --subnet-mode custom

# Create the subnet within this VPC
gcloud compute networks subnets create network-b-subnet --network network-b \
    --range 10.8.0.0/16 --region $REGION_2

# Create the VM instance
gcloud compute instances create vm-b --zone $ZONE_2 --network network-b --subnet network-b-subnet --machine-type e2-small

# Enable SSH and ICMP firewall rules
gcloud compute firewall-rules create network-b-fw --network network-b --allow tcp:22,icmp

gcloud config set project $PROJECT_ID

gcloud compute networks peerings create peer-ab \
    --network=network-a \
    --peer-project=$PROJECT_ID_2 \
    --peer-network=network-b 

gcloud config set project $PROJECT_ID_2

gcloud compute networks peerings create peer-ba \
    --network=network-b \
    --peer-project=$PROJECT_ID \
    --peer-network=network-a

echo "${RED}${BOLD}Congratulations${RESET}" "${WHITE}${BOLD}for${RESET}" "${GREEN}${BOLD}Completing the Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#