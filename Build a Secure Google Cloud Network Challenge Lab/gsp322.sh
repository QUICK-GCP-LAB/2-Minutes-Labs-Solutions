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

gcloud compute firewall-rules delete open-access --quiet

gcloud compute instances start bastion \
    --project=$DEVSHELL_PROJECT_ID \
    --zone=$ZONE
 
gcloud compute firewall-rules create ssh-ingress --allow=tcp:22 --source-ranges 35.235.240.0/20 --target-tags $IAP_NET_TAG --network acme-vpc
 
gcloud compute instances add-tags bastion --tags=$IAP_NET_TAG --zone=$ZONE
 
gcloud compute firewall-rules create http-ingress --allow=tcp:80 --source-ranges 0.0.0.0/0 --target-tags $HTTP_NET_TAG --network acme-vpc
 
gcloud compute instances add-tags juice-shop --tags=$HTTP_NET_TAG --zone=$ZONE
 
gcloud compute firewall-rules create internal-ssh-ingress --allow=tcp:22 --source-ranges 192.168.10.0/24 --target-tags $INT_NET_TAG --network acme-vpc
 
gcloud compute instances add-tags juice-shop --tags=$INT_NET_TAG --zone=$ZONE

sleep 30

cat > prepare_disk.sh <<'EOF_END'

export ZONE=$(gcloud compute instances list juice-shop --format 'csv[no-heading](zone)')

gcloud compute ssh juice-shop --internal-ip --zone=$ZONE --quiet

EOF_END

gcloud compute scp prepare_disk.sh bastion:/tmp --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet

gcloud compute ssh bastion --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet --command="bash /tmp/prepare_disk.sh"

echo "${RED}${BOLD}Congratulations${RESET}" "${WHITE}${BOLD}for${RESET}" "${GREEN}${BOLD}Completing the Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#