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

export REGION_1=${ZONE::-2}

gcloud compute networks create managementnet --subnet-mode=custom

gcloud compute networks subnets create managementsubnet-$REGION_1 --network=managementnet --region=$REGION_1 --range=10.130.0.0/20

gcloud compute networks create privatenet --subnet-mode=custom

gcloud compute networks subnets create privatesubnet-$REGION_1 --network=privatenet --region=$REGION_1 --range=172.16.0.0/24

gcloud compute networks subnets create privatesubnet-$REGION_2 --network=privatenet --region=$REGION_2 --range=172.20.0.0/20

gcloud compute firewall-rules create managementnet-allow-icmp-ssh-rdp --direction=INGRESS --priority=1000 --network=managementnet --action=ALLOW --rules=icmp,tcp:22,tcp:3389 --source-ranges=0.0.0.0/0

gcloud compute firewall-rules create privatenet-allow-icmp-ssh-rdp --direction=INGRESS --priority=1000 --network=privatenet --action=ALLOW --rules=icmp,tcp:22,tcp:3389 --source-ranges=0.0.0.0/0

gcloud compute instances create	managementnet-${REGION_1}-vm --zone=$ZONE --machine-type=e2-micro --subnet=managementsubnet-$REGION_1

gcloud compute instances create privatenet-${REGION_1}-vm --zone=$ZONE --machine-type=e2-micro --subnet=privatesubnet-$REGION_1

gcloud compute instances create vm-appliance \
--zone=$ZONE \
--machine-type=e2-standard-4 \
--network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=privatesubnet-$REGION_1 \
--network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=managementsubnet-$REGION_1 \
--network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=mynetwork

echo "${RED}${BOLD}Congratulations${RESET}" "${WHITE}${BOLD}for${RESET}" "${GREEN}${BOLD}Completing the Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#