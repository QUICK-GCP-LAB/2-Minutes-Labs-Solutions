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

echo "${YELLOW}${BOLD}

Starting Execution 

${RESET}"

export REGION_1="${ZONE_1%-*}"

export REGION_2="${ZONE_2%-*}"

gcloud compute networks create vpn-network-1 --subnet-mode custom

gcloud compute networks subnets create subnet-a \
--network vpn-network-1 --range 10.1.1.0/24 --region "$REGION_1"

gcloud compute firewall-rules create network-1-allow-custom \
  --network vpn-network-1 \
  --allow tcp:0-65535,udp:0-65535,icmp \
  --source-ranges 10.0.0.0/8

gcloud compute firewall-rules create network-1-allow-ssh-icmp \
    --network vpn-network-1 \
    --allow tcp:22,icmp

gcloud compute instances create server-1 --machine-type=e2-medium --zone $ZONE_1 --subnet subnet-a

echo "${GREEN}${BOLD}

Task 1. Set up a Global VPC environment Complete

${RESET}"

gcloud compute networks create vpn-network-2 --subnet-mode custom

gcloud compute networks subnets create subnet-b \
--network vpn-network-2 --range 192.168.1.0/24 --region $REGION_2

gcloud compute firewall-rules create network-2-allow-custom \
  --network vpn-network-2 \
  --allow tcp:0-65535,udp:0-65535,icmp \
  --source-ranges 192.168.0.0/16

gcloud compute firewall-rules create network-2-allow-ssh-icmp \
    --network vpn-network-2 \
    --allow tcp:22,icmp

gcloud compute instances create server-2 --machine-type=e2-medium --zone $ZONE_2 --subnet subnet-b

echo "${GREEN}${BOLD}

Task 2. Set up a simulated on-premises environment Complete

${RESET}"

echo "${YELLOW}${BOLD}

Reserve two static IP addresses

${RESET}"

gcloud compute addresses create vpn-1-static-ip --project=$DEVSHELL_PROJECT_ID --region=$REGION_1

gcloud compute addresses create vpn-2-static-ip --project=$DEVSHELL_PROJECT_ID --region=$REGION_2

IP_ADDRESS_1=$(gcloud compute addresses describe vpn-1-static-ip --region=$REGION_1 --format="get(address)")

IP_ADDRESS_2=$(gcloud compute addresses describe vpn-2-static-ip --region=$REGION_2 --format="get(address)")

echo "${YELLOW}${BOLD}

Create the vpn-1 gateway and tunnel1to2

${RESET}"

gcloud compute target-vpn-gateways create vpn-1 --project=$DEVSHELL_PROJECT_ID --region=$REGION_1 --network=vpn-network-1

gcloud compute forwarding-rules create vpn-1-rule-esp --project=$DEVSHELL_PROJECT_ID --region=$REGION_1 --address=$IP_ADDRESS_1 --ip-protocol=ESP --target-vpn-gateway=vpn-1

gcloud compute forwarding-rules create vpn-1-rule-udp500 --project=$DEVSHELL_PROJECT_ID --region=$REGION_1 --address=$IP_ADDRESS_1 --ip-protocol=UDP --ports=500 --target-vpn-gateway=vpn-1

gcloud compute forwarding-rules create vpn-1-rule-udp4500 --project=$DEVSHELL_PROJECT_ID --region=$REGION_1 --address=$IP_ADDRESS_1 --ip-protocol=UDP --ports=4500 --target-vpn-gateway=vpn-1

gcloud compute vpn-tunnels create tunnel1to2 --project=$DEVSHELL_PROJECT_ID --region=$REGION_1 --peer-address=$IP_ADDRESS_2 --shared-secret=gcprocks --ike-version=2 --local-traffic-selector=0.0.0.0/0 --remote-traffic-selector=0.0.0.0/0 --target-vpn-gateway=vpn-1

gcloud compute routes create tunnel1to2-route-1 --project=$DEVSHELL_PROJECT_ID --network=vpn-network-1 --priority=1000 --destination-range=192.168.1.0/24 --next-hop-vpn-tunnel=tunnel1to2 --next-hop-vpn-tunnel-region=$REGION_1

echo "${YELLOW}${BOLD}

Create the vpn-2 gateway and tunnel2to1

${RESET}"

gcloud compute target-vpn-gateways create vpn-2 --project=$DEVSHELL_PROJECT_ID --region=$REGION_2 --network=vpn-network-2

gcloud compute forwarding-rules create vpn-2-rule-esp --project=$DEVSHELL_PROJECT_ID --region=$REGION_2 --address=$IP_ADDRESS_2 --ip-protocol=ESP --target-vpn-gateway=vpn-2

gcloud compute forwarding-rules create vpn-2-rule-udp500 --project=$DEVSHELL_PROJECT_ID --region=$REGION_2 --address=$IP_ADDRESS_2 --ip-protocol=UDP --ports=500 --target-vpn-gateway=vpn-2

gcloud compute forwarding-rules create vpn-2-rule-udp4500 --project=$DEVSHELL_PROJECT_ID --region=$REGION_2 --address=$IP_ADDRESS_2 --ip-protocol=UDP --ports=4500 --target-vpn-gateway=vpn-2

gcloud compute vpn-tunnels create tunnel2to1 --project=$DEVSHELL_PROJECT_ID --region=$REGION_2 --peer-address=$IP_ADDRESS_1 --shared-secret=gcprocks --ike-version=2 --local-traffic-selector=0.0.0.0/0 --remote-traffic-selector=0.0.0.0/0 --target-vpn-gateway=vpn-2

gcloud compute routes create tunnel2to1-route-1 --project=$DEVSHELL_PROJECT_ID --network=vpn-network-2 --priority=1000 --destination-range=10.1.1.0/24 --next-hop-vpn-tunnel=tunnel2to1 --next-hop-vpn-tunnel-region=$REGION_2

echo "${GREEN}${BOLD}

Task 4. Create the VPN gateways and tunnels

${RESET}"

echo "${RED}${BOLD}

Congratulations for Completing the Lab !!!

${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#