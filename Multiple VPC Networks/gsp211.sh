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

# Get zone and region information from existing instances
export ZONE_1=$(gcloud compute instances list mynet-vm-1 --format 'csv[no-heading](zone)')
export ZONE_2=$(gcloud compute instances list mynet-vm-2 --format 'csv[no-heading](zone)')

export REGION_1=$(echo "$ZONE_1" | cut -d '-' -f 1-2)
export REGION_2=$(echo "$ZONE_2" | cut -d '-' -f 1-2)

echo "Zone 1: $ZONE_1"
echo "Region 1: $REGION_1"
echo "Zone 2: $ZONE_2"
echo "Region 2: $REGION_2"

# Create the management network
gcloud compute networks create managementnet --subnet-mode=custom

# Create the management subnet in the first region
gcloud compute networks subnets create managementsubnet-1 --network=managementnet --region=$REGION_1 --range=10.130.0.0/20

# Create the private network
gcloud compute networks create privatenet --subnet-mode=custom

# Create the first private subnet in the first region
gcloud compute networks subnets create privatesubnet-1 --network=privatenet --region=$REGION_1 --range=172.16.0.0/24

# Create the second private subnet in the second region
gcloud compute networks subnets create privatesubnet-2 --network=privatenet --region=$REGION_2 --range=172.20.0.0/20

# Create Firewall Rules (should be done before creating instances)
gcloud compute firewall-rules create managementnet-allow-icmp-ssh-rdp --direction=INGRESS --priority=1000 --network=managementnet --action=ALLOW --rules=icmp,tcp:22,tcp:3389 --source-ranges=0.0.0.0/0
gcloud compute firewall-rules create privatenet-allow-icmp-ssh-rdp --direction=INGRESS --priority=1000 --network=privatenet --action=ALLOW --rules=icmp,tcp:22,tcp:3389 --source-ranges=0.0.0.0/0

# Create Instances
gcloud compute instances create managementnet-vm-1 --zone=$ZONE_1 --machine-type=e2-micro --subnet=managementsubnet-1
gcloud compute instances create privatenet-vm-1 --zone=$ZONE_1 --machine-type=e2-micro --subnet=privatesubnet-1

# Create the appliance instance
gcloud compute instances create vm-appliance \
--zone=$ZONE_1 \
--machine-type=e2-standard-4 \
--network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=privatesubnet-1 \
--network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=managementsubnet-1 \
--network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=mynetwork

echo "${BG_RED}${BOLD}Congratulations For Completing The Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#
