clear

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

# Array of color codes excluding black and white
TEXT_COLORS=($RED $GREEN $YELLOW $BLUE $MAGENTA $CYAN)
BG_COLORS=($BG_RED $BG_GREEN $BG_YELLOW $BG_BLUE $BG_MAGENTA $BG_CYAN)

# Pick random colors
RANDOM_TEXT_COLOR=${TEXT_COLORS[$RANDOM % ${#TEXT_COLORS[@]}]}
RANDOM_BG_COLOR=${BG_COLORS[$RANDOM % ${#BG_COLORS[@]}]}

#----------------------------------------------------start--------------------------------------------------#

echo "${RANDOM_BG_COLOR}${RANDOM_TEXT_COLOR}${BOLD}Starting Execution${RESET}"

# Step 1: Enable required GCP service
echo "${MAGENTA}${BOLD}Enabling networkconnectivity.googleapis.com service...${RESET}"
gcloud services enable networkconnectivity.googleapis.com

# Step 2: Set project ID
echo "${BLUE}${BOLD}Setting project ID...${RESET}"
export PROJECT_ID=$(gcloud config get-value project)

# Step 3: Get project number
echo "${CYAN}${BOLD}Getting project number...${RESET}"
export PROJECT_NUMBER=$(gcloud projects describe ${PROJECT_ID} \
    --format="value(projectNumber)")

# Step 4: Get default zone
echo "${MAGENTA}${BOLD}Getting default zone...${RESET}"
export ZONE_1=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")

# Step 5: Get default region
echo "${RED}${BOLD}Getting default region...${RESET}"
export REGION_1=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")

# Step 6: Derive second region
echo "${GREEN}${BOLD}Deriving second region from $ZONE_2...${RESET}"
export REGION_2=$(echo "$ZONE_2" | cut -d '-' -f 1-2)

# Step 7: Delete default VPC
echo "${YELLOW}${BOLD}Deleting default VPC...${RESET}"
gcloud compute networks delete default --quiet

# Step 8: Create transit VPC
echo "${BLUE}${BOLD}Creating transit VPC...${RESET}"
gcloud compute networks create vpc-transit \
  --subnet-mode=custom \
  --bgp-routing-mode=global

# Step 9: Create VPC-A
echo "${CYAN}${BOLD}Creating VPC-A...${RESET}"
gcloud compute networks create vpc-a --subnet-mode=custom --mtu=1460 --bgp-routing-mode=regional

# Step 10: Create VPC-A subnet
echo "${MAGENTA}${BOLD}Creating VPC-A subnet...${RESET}"
gcloud compute networks subnets create vpc-a-sub1-use4 --range=10.20.10.0/24 --stack-type=IPV4_ONLY --network=vpc-a --region=$REGION_1

# Step 11: Create VPC-B
echo "${RED}${BOLD}Creating VPC-B...${RESET}"
gcloud compute networks create vpc-b --subnet-mode=custom --mtu=1460 --bgp-routing-mode=regional

# Step 12: Create VPC-B subnet
echo "${GREEN}${BOLD}Creating VPC-B subnet...${RESET}"
gcloud compute networks subnets create vpc-b-sub1-usw2 --range=10.20.20.0/24 --stack-type=IPV4_ONLY --network=vpc-b --region=$REGION_2

# Step 13: Create routers for transit VPC in Region 1
echo "${YELLOW}${BOLD}Creating routers for transit VPC in $REGION_1...${RESET}"
gcloud compute routers create cr-vpc-transit-use4-1 --region=$REGION_1 --network=vpc-transit --asn=65000

# Step 14: Create routers for transit VPC in Region 2
echo "${BLUE}${BOLD}Creating routers for transit VPC in $REGION_2...${RESET}"
gcloud compute routers create cr-vpc-transit-usw2-1 --region=$REGION_2 --network=vpc-transit --asn=65000

# Step 15: Create routers for VPC-A
echo "${CYAN}${BOLD}Creating routers for VPC-A...${RESET}"
gcloud compute routers create cr-vpc-a-use4-1 --region=$REGION_1 --network=vpc-a --asn=65001

# Step 16: Create routers for VPC-B
echo "${MAGENTA}${BOLD}Creating routers for VPC-B...${RESET}"
gcloud compute routers create cr-vpc-b-usw2-1 --region=$REGION_2 --network=vpc-b --asn=65002

# Step 17: Create VPN gateway for transit in Region 1
echo "${GREEN}${BOLD}Creating VPN Gateway for Transit in $REGION_1...${RESET}"
gcloud compute vpn-gateways create vpc-transit-gw1-use4 --region=$REGION_1 --network=vpc-transit

# Step 18: Create VPN gateway for transit in Region 2
echo "${YELLOW}${BOLD}Creating VPN Gateway for Transit in $REGION_2...${RESET}"
gcloud compute vpn-gateways create vpc-transit-gw1-usw2 --region=$REGION_2 --network=vpc-transit

# Step 19: Create VPN gateway for VPC-A in Region 1
echo "${BLUE}${BOLD}Creating VPN Gateway for VPC-A in $REGION_1...${RESET}"
gcloud compute vpn-gateways create vpc-a-gw1-use4 --region=$REGION_1 --network=vpc-a

# Step 20: Create VPN gateway for VPC-B in Region 2
echo "${CYAN}${BOLD}Creating VPN Gateway for VPC-B in $REGION_2...${RESET}"
gcloud compute vpn-gateways create vpc-b-gw1-usw2 --region=$REGION_2 --network=vpc-b

# Step 21: Create VPN tunnel from Transit to VPC-A (Tunnel 1)
echo "${MAGENTA}${BOLD}Creating VPN Tunnel from Transit to VPC-A (Tunnel 1)...${RESET}"
gcloud compute vpn-tunnels create transit-to-vpc-a-tu1 \
  --region=$REGION_1 \
  --vpn-gateway=vpc-transit-gw1-use4 \
  --peer-gcp-gateway=projects/$DEVSHELL_PROJECT_ID/regions/$REGION_1/vpnGateways/vpc-a-gw1-use4 \
  --router=cr-vpc-transit-use4-1 \
  --ike-version=2 \
  --shared-secret=gcprocks \
  --interface=0

# Step 22: Create VPN tunnel from Transit to VPC-A (Tunnel 2)
echo "${RED}${BOLD}Creating VPN Tunnel from Transit to VPC-A (Tunnel 2)...${RESET}"
gcloud compute vpn-tunnels create transit-to-vpc-a-tu2 \
  --region=$REGION_1 \
  --vpn-gateway=vpc-transit-gw1-use4 \
  --peer-gcp-gateway=projects/$DEVSHELL_PROJECT_ID/regions/$REGION_1/vpnGateways/vpc-a-gw1-use4 \
  --router=cr-vpc-transit-use4-1 \
  --ike-version=2 \
  --shared-secret=gcprocks \
  --interface=1

# Step 23: Add interface for VPN tunnel from Transit to VPC-A (Tunnel 1)
echo "${GREEN}${BOLD}Adding Interface for VPN Tunnel from Transit to VPC-A (Tunnel 1)...${RESET}"
gcloud compute routers add-interface cr-vpc-transit-use4-1 \
  --interface-name=transit-to-vpc-a-tu1 \
  --vpn-tunnel=transit-to-vpc-a-tu1 \
  --region=$REGION_1 \
  --ip-address=169.254.1.1 \
  --mask-length=30

# Step 24: Add BGP peer for VPN tunnel from Transit to VPC-A (Tunnel 1)
echo "${YELLOW}${BOLD}Adding BGP Peer for VPN Tunnel from Transit to VPC-A (Tunnel 1)...${RESET}"
gcloud compute routers add-bgp-peer cr-vpc-transit-use4-1 \
  --peer-name=transit-to-vpc-a-bgp1 \
  --peer-asn=65001 \
  --interface=transit-to-vpc-a-tu1 \
  --advertisement-mode=custom \
  --peer-ip-address=169.254.1.2 \
  --region=$REGION_1

# Step 25: Add interface for VPN tunnel from Transit to VPC-A (Tunnel 2)
echo "${BLUE}${BOLD}Adding Interface for VPN Tunnel from Transit to VPC-A (Tunnel 2)...${RESET}"
gcloud compute routers add-interface cr-vpc-transit-use4-1 \
  --interface-name=transit-to-vpc-a-tu2 \
  --vpn-tunnel=transit-to-vpc-a-tu2 \
  --region=$REGION_1 \
  --ip-address=169.254.1.5 \
  --mask-length=30

# Step 26: Add BGP peer for VPN tunnel from Transit to VPC-A (Tunnel 2)
echo "${CYAN}${BOLD}Adding BGP Peer for VPN Tunnel from Transit to VPC-A (Tunnel 2)...${RESET}"
gcloud compute routers add-bgp-peer cr-vpc-transit-use4-1 \
  --peer-name=transit-to-vpc-a-bgp2 \
  --peer-asn=65001 \
  --interface=vpc-a-to-transit-tu2 \
  --advertisement-mode=custom \
  --peer-ip-address=169.254.1.6 \
  --region=$REGION_1

# Step 27: Create VPN tunnel from VPC-A to Transit (Tunnel 1)
echo "${MAGENTA}${BOLD}Creating VPN Tunnel from VPC-A to Transit (Tunnel 1)...${RESET}"
gcloud compute vpn-tunnels create vpc-a-to-transit-tu1 \
  --region=$REGION_1 \
  --vpn-gateway=vpc-a-gw1-use4 \
  --peer-gcp-gateway=projects/$DEVSHELL_PROJECT_ID/regions/$REGION_1/vpnGateways/vpc-transit-gw1-use4 \
  --router=cr-vpc-a-use4-1 \
  --ike-version=2 \
  --shared-secret=gcprocks \
  --interface=0

# Step 28: Create VPN tunnel from VPC-A to Transit (Tunnel 2)
echo "${RED}${BOLD}Creating VPN Tunnel from VPC-A to Transit (Tunnel 2)...${RESET}"
gcloud compute vpn-tunnels create vpc-a-to-transit-tu2 \
  --region=$REGION_1 \
  --vpn-gateway=vpc-a-gw1-use4 \
  --peer-gcp-gateway=projects/$DEVSHELL_PROJECT_ID/regions/$REGION_1/vpnGateways/vpc-transit-gw1-use4 \
  --router=cr-vpc-a-use4-1 \
  --ike-version=2 \
  --shared-secret=gcprocks \
  --interface=1

# Step 29: Add interface for VPN tunnel from VPC-A to Transit (Tunnel 1)
echo "${GREEN}${BOLD}Adding Interface for VPN Tunnel from VPC-A to Transit (Tunnel 1)...${RESET}"
gcloud compute routers add-interface cr-vpc-a-use4-1 \
  --interface-name=vpc-a-to-transit-tu1 \
  --vpn-tunnel=vpc-a-to-transit-tu1 \
  --region=$REGION_1 \
  --ip-address=169.254.1.2 \
  --mask-length=30

# Step 30: Add BGP peer for VPN tunnel from VPC-A to Transit (Tunnel 1)
echo "${YELLOW}${BOLD}Adding BGP Peer for VPN Tunnel from VPC-A to Transit (Tunnel 1)...${RESET}"
gcloud compute routers add-bgp-peer cr-vpc-a-use4-1 \
  --peer-name=vpc-a-to-transit-bgp1 \
  --peer-asn=65000 \
  --interface=vpc-a-to-transit-tu1 \
  --advertisement-mode=custom \
  --peer-ip-address=169.254.1.1 \
  --region=$REGION_1

# Step 31: Add interface for VPN tunnel from VPC-A to Transit (Tunnel 2)
echo "${BLUE}${BOLD}Adding Interface for VPN Tunnel from VPC-A to Transit (Tunnel 2)...${RESET}"
gcloud compute routers add-interface cr-vpc-a-use4-1 \
  --interface-name=vpc-a-to-transit-tu2 \
  --vpn-tunnel=vpc-a-to-transit-tu2 \
  --region=$REGION_1 \
  --ip-address=169.254.1.6 \
  --mask-length=30

# Step 32: Add BGP peer for VPN tunnel from VPC-A to Transit (Tunnel 2)
echo "${CYAN}${BOLD}Adding BGP Peer for VPN Tunnel from VPC-A to Transit (Tunnel 2)...${RESET}"
gcloud compute routers add-bgp-peer cr-vpc-a-use4-1 \
  --peer-name=vpc-a-to-transit-bgp2 \
  --peer-asn=65000 \
  --interface=vpc-a-to-transit-tu2 \
  --advertisement-mode=custom \
  --peer-ip-address=169.254.1.5 \
  --region=$REGION_1

# Step 33: Create VPN tunnel from Transit to VPC-B (Tunnel 1)
echo "${MAGENTA}${BOLD}Creating VPN Tunnel from Transit to VPC-B (Tunnel 1)...${RESET}"
gcloud compute vpn-tunnels create transit-to-vpc-b-tu1 \
  --region=$REGION_2 \
  --vpn-gateway=vpc-transit-gw1-usw2 \
  --peer-gcp-gateway=projects/$DEVSHELL_PROJECT_ID/regions/$REGION_2/vpnGateways/vpc-b-gw1-usw2 \
  --router=cr-vpc-transit-usw2-1 \
  --ike-version=2 \
  --shared-secret=gcprocks \
  --interface=0

# Step 34: Create VPN tunnel from Transit to VPC-B (Tunnel 2)
echo "${RED}${BOLD}Creating VPN Tunnel from Transit to VPC-B (Tunnel 2)...${RESET}"
gcloud compute vpn-tunnels create transit-to-vpc-b-tu2 \
  --region=$REGION_2 \
  --vpn-gateway=vpc-transit-gw1-usw2 \
  --peer-gcp-gateway=projects/$DEVSHELL_PROJECT_ID/regions/$REGION_2/vpnGateways/vpc-b-gw1-usw2 \
  --router=cr-vpc-transit-usw2-1 \
  --ike-version=2 \
  --shared-secret=gcprocks \
  --interface=1

# Step 35: Add interface for VPN tunnel from Transit to VPC-B (Tunnel 1)
echo "${GREEN}${BOLD}Adding Interface for VPN Tunnel from Transit to VPC-B (Tunnel 1)...${RESET}"
gcloud compute routers add-interface cr-vpc-transit-usw2-1 \
  --interface-name=transit-to-vpc-b-tu1 \
  --vpn-tunnel=transit-to-vpc-b-tu1 \
  --region=$REGION_2 \
  --ip-address=169.254.1.9 \
  --mask-length=30

# Step 36: Add BGP peer for VPN tunnel from Transit to VPC-B (Tunnel 1)
echo "${YELLOW}${BOLD}Adding BGP Peer for VPN Tunnel from Transit to VPC-B (Tunnel 1)...${RESET}"
gcloud compute routers add-bgp-peer cr-vpc-transit-usw2-1 \
  --peer-name=transit-to-vpc-b-bgp1 \
  --peer-asn=65002 \
  --interface=transit-to-vpc-b-tu1 \
  --advertisement-mode=custom \
  --peer-ip-address=169.254.1.10 \
  --region=$REGION_2

# Step 37: Add interface for VPN tunnel from Transit to VPC-B (Tunnel 2)
echo "${BLUE}${BOLD}Adding Interface for VPN Tunnel from Transit to VPC-B (Tunnel 2)...${RESET}"
gcloud compute routers add-interface cr-vpc-transit-usw2-1 \
  --interface-name=transit-to-vpc-b-tu2 \
  --vpn-tunnel=transit-to-vpc-b-tu2 \
  --region=$REGION_2 \
  --ip-address=169.254.1.13 \
  --mask-length=30

# Step 38: Add BGP peer for VPN tunnel from Transit to VPC-B (Tunnel 2)
echo "${CYAN}${BOLD}Adding BGP Peer for VPN Tunnel from Transit to VPC-B (Tunnel 2)...${RESET}"
gcloud compute routers add-bgp-peer cr-vpc-transit-usw2-1 \
  --peer-name=transit-to-vpc-b-bgp2 \
  --peer-asn=65002 \
  --interface=vpc-b-to-transit-tu2 \
  --advertisement-mode=custom \
  --peer-ip-address=169.254.1.14 \
  --region=$REGION_2

# Step 39: Create VPN tunnel from VPC-B to Transit (Tunnel 1)
echo "${MAGENTA}${BOLD}Creating VPN Tunnel from VPC-B to Transit (Tunnel 1)...${RESET}"
gcloud compute vpn-tunnels create vpc-b-to-transit-tu1 \
  --region=$REGION_2 \
  --vpn-gateway=vpc-b-gw1-usw2 \
  --peer-gcp-gateway=projects/$DEVSHELL_PROJECT_ID/regions/$REGION_2/vpnGateways/vpc-transit-gw1-usw2 \
  --router=cr-vpc-b-usw2-1 \
  --ike-version=2 \
  --shared-secret=gcprocks \
  --interface=0

# Step 40: Create VPN tunnel from VPC-B to Transit (Tunnel 2)
echo "${RED}${BOLD}Creating VPN Tunnel from VPC-B to Transit (Tunnel 2)...${RESET}"
gcloud compute vpn-tunnels create vpc-b-to-transit-tu2 \
  --region=$REGION_2 \
  --vpn-gateway=vpc-b-gw1-usw2 \
  --peer-gcp-gateway=projects/$DEVSHELL_PROJECT_ID/regions/$REGION_2/vpnGateways/vpc-transit-gw1-usw2 \
  --router=cr-vpc-b-usw2-1 \
  --ike-version=2 \
  --shared-secret=gcprocks \
  --interface=1

# Step 41: Add interface for VPN tunnel from VPC-B to Transit (Tunnel 1)
echo "${GREEN}${BOLD}Adding Interface for VPN Tunnel from VPC-B to Transit (Tunnel 1)...${RESET}"
gcloud compute routers add-interface cr-vpc-b-usw2-1 \
  --interface-name=vpc-b-to-transit-tu1 \
  --vpn-tunnel=vpc-b-to-transit-tu1 \
  --region=$REGION_2 \
  --ip-address=169.254.1.10 \
  --mask-length=30

# Step 42: Add BGP peer for VPN tunnel from VPC-B to Transit (Tunnel 1)
echo "${YELLOW}${BOLD}Adding BGP Peer for VPN Tunnel from VPC-B to Transit (Tunnel 1)...${RESET}"
gcloud compute routers add-bgp-peer cr-vpc-b-usw2-1 \
  --peer-name=vpc-b-to-transit-bgp1 \
  --peer-asn=65000 \
  --interface=vpc-b-to-transit-tu1 \
  --advertisement-mode=custom \
  --peer-ip-address=169.254.1.9 \
  --region=$REGION_2

# Step 43: Add interface for VPN tunnel from VPC-B to Transit (Tunnel 2)
echo "${BLUE}${BOLD}Adding Interface for VPN Tunnel from VPC-B to Transit (Tunnel 2)...${RESET}"
gcloud compute routers add-interface cr-vpc-b-usw2-1 \
  --interface-name=vpc-b-to-transit-tu2 \
  --vpn-tunnel=vpc-b-to-transit-tu2 \
  --region=$REGION_2 \
  --ip-address=169.254.1.14 \
  --mask-length=30

# Step 44: Add BGP peer for VPN tunnel from VPC-B to Transit (Tunnel 2)
echo "${CYAN}${BOLD}Adding BGP Peer for VPN Tunnel from VPC-B to Transit (Tunnel 2)...${RESET}"
gcloud compute routers add-bgp-peer cr-vpc-b-usw2-1 \
  --peer-name=vpc-b-to-transit-bgp2 \
  --peer-asn=65000 \
  --interface=vpc-b-to-transit-tu2 \
  --advertisement-mode=custom \
  --peer-ip-address=169.254.1.13 \
  --region=$REGION_2

# Step 45: Create Transit Hub
echo "${MAGENTA}${BOLD}Creating Transit Hub...${RESET}"
gcloud alpha network-connectivity hubs create transit-hub \
   --description=Transit_hub

# Step 46: Create Spoke for Branch Office 1 (Region 1)
echo "${RED}${BOLD}Creating Spoke for Branch Office 1 ($REGION_1)...${RESET}"
gcloud alpha network-connectivity spokes create bo1 \
    --hub=transit-hub \
    --description=branch_office1 \
    --vpn-tunnel=transit-to-vpc-a-tu1,transit-to-vpc-a-tu2 \
    --region=$REGION_1

# Step 47: Create Spoke for Branch Office 2 (Region 2)
echo "${GREEN}${BOLD}Creating Spoke for Branch Office 2 ($REGION_2)...${RESET}"
gcloud alpha network-connectivity spokes create bo2 \
    --hub=transit-hub \
    --description=branch_office2 \
    --vpn-tunnel=transit-to-vpc-b-tu1,transit-to-vpc-b-tu2 \
    --region=$REGION_2

# Step 48: Create Firewall Rule for VPC-A
echo "${YELLOW}${BOLD}Creating Firewall Rule for VPC-A...${RESET}"
gcloud compute firewall-rules create fw-a --direction=INGRESS --priority=1000 --network=vpc-a --action=ALLOW --rules=tcp:22 --source-ranges=0.0.0.0/0

# Step 49: Create Firewall Rule for VPC-B
echo "${BLUE}${BOLD}Creating Firewall Rule for VPC-B...${RESET}"
gcloud compute firewall-rules create fw-b --direction=INGRESS --priority=1000 --network=vpc-b --action=ALLOW --rules=tcp:22 --source-ranges=0.0.0.0/0

# Step 50: Create VM in VPC-A
echo "${CYAN}${BOLD}Creating VM in VPC-A...${RESET}"
gcloud compute instances create vpc-a-vm-1 \
    --zone=$ZONE_1 \
    --machine-type=e2-medium \
    --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=vpc-a-sub1-use4 \
    --metadata=enable-oslogin=true \
    --maintenance-policy=MIGRATE \
    --provisioning-model=STANDARD \
    --service-account=$PROJECT_NUMBER-compute@developer.gserviceaccount.com \
    --scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/trace.append \
    --create-disk=auto-delete=yes,boot=yes,device-name=vpc-a-vm-1,image=projects/debian-cloud/global/images/debian-11-bullseye-v20241210,mode=rw,size=10,type=pd-balanced \
    --no-shielded-secure-boot \
    --shielded-vtpm \
    --shielded-integrity-monitoring \
    --labels=goog-ec-src=vm_add-gcloud \
    --reservation-affinity=any

# Step 51: Create VM in VPC-B
echo "${MAGENTA}${BOLD}Creating VM in VPC-B...${RESET}"
gcloud compute instances create vpc-b-vm-1 \
    --zone=$ZONE_2 \
    --machine-type=e2-medium \
    --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=vpc-b-sub1-usw2 \
    --metadata=enable-oslogin=true \
    --maintenance-policy=MIGRATE \
    --provisioning-model=STANDARD \
    --service-account=$PROJECT_NUMBER-compute@developer.gserviceaccount.com \
    --scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/trace.append \
    --create-disk=auto-delete=yes,boot=yes,device-name=vpc-b-vm-1,image=projects/debian-cloud/global/images/debian-11-bullseye-v20241210,mode=rw,size=10,type=pd-balanced \
    --no-shielded-secure-boot \
    --shielded-vtpm \
    --shielded-integrity-monitoring \
    --labels=goog-ec-src=vm_add-gcloud \
    --reservation-affinity=any

# Final URL for Firewall Rule for VPC-A
echo "${CYAN}${BOLD}Click here to manage the Firewall Rule for VPC-A:${RESET}" "https://console.cloud.google.com/net-security/firewall-manager/firewall-policies/details/fw-a?project=$PROJECT_ID"
echo
echo "${MAGENTA}${BOLD}Click here to manage the Firewall Rule for VPC-B:${RESET}" "https://console.cloud.google.com/net-security/firewall-manager/firewall-policies/details/fw-b?project=$PROJECT_ID"
echo

# Function to display a random congratulatory message
function random_congrats() {
    MESSAGES=(
        "${GREEN}Congratulations For Completing The Lab! Keep up the great work!${RESET}"
        "${CYAN}Well done! Your hard work and effort have paid off!${RESET}"
        "${YELLOW}Amazing job! You’ve successfully completed the lab!${RESET}"
        "${BLUE}Outstanding! Your dedication has brought you success!${RESET}"
        "${MAGENTA}Great work! You’re one step closer to mastering this!${RESET}"
        "${RED}Fantastic effort! You’ve earned this achievement!${RESET}"
        "${CYAN}Congratulations! Your persistence has paid off brilliantly!${RESET}"
        "${GREEN}Bravo! You’ve completed the lab with flying colors!${RESET}"
        "${YELLOW}Excellent job! Your commitment is inspiring!${RESET}"
        "${BLUE}You did it! Keep striving for more successes like this!${RESET}"
        "${MAGENTA}Kudos! Your hard work has turned into a great accomplishment!${RESET}"
        "${RED}You’ve smashed it! Completing this lab shows your dedication!${RESET}"
        "${CYAN}Impressive work! You’re making great strides!${RESET}"
        "${GREEN}Well done! This is a big step towards mastering the topic!${RESET}"
        "${YELLOW}You nailed it! Every step you took led you to success!${RESET}"
        "${BLUE}Exceptional work! Keep this momentum going!${RESET}"
        "${MAGENTA}Fantastic! You’ve achieved something great today!${RESET}"
        "${RED}Incredible job! Your determination is truly inspiring!${RESET}"
        "${CYAN}Well deserved! Your effort has truly paid off!${RESET}"
        "${GREEN}You’ve got this! Every step was a success!${RESET}"
        "${YELLOW}Nice work! Your focus and effort are shining through!${RESET}"
        "${BLUE}Superb performance! You’re truly making progress!${RESET}"
        "${MAGENTA}Top-notch! Your skill and dedication are paying off!${RESET}"
        "${RED}Mission accomplished! This success is a reflection of your hard work!${RESET}"
        "${CYAN}You crushed it! Keep pushing towards your goals!${RESET}"
        "${GREEN}You did a great job! Stay motivated and keep learning!${RESET}"
        "${YELLOW}Well executed! You’ve made excellent progress today!${RESET}"
        "${BLUE}Remarkable! You’re on your way to becoming an expert!${RESET}"
        "${MAGENTA}Keep it up! Your persistence is showing impressive results!${RESET}"
        "${RED}This is just the beginning! Your hard work will take you far!${RESET}"
        "${CYAN}Terrific work! Your efforts are paying off in a big way!${RESET}"
        "${GREEN}You’ve made it! This achievement is a testament to your effort!${RESET}"
        "${YELLOW}Excellent execution! You’re well on your way to mastering the subject!${RESET}"
        "${BLUE}Wonderful job! Your hard work has definitely paid off!${RESET}"
        "${MAGENTA}You’re amazing! Keep up the awesome work!${RESET}"
        "${RED}What an achievement! Your perseverance is truly admirable!${RESET}"
        "${CYAN}Incredible effort! This is a huge milestone for you!${RESET}"
        "${GREEN}Awesome! You’ve done something incredible today!${RESET}"
        "${YELLOW}Great job! Keep up the excellent work and aim higher!${RESET}"
        "${BLUE}You’ve succeeded! Your dedication is your superpower!${RESET}"
        "${MAGENTA}Congratulations! Your hard work has brought great results!${RESET}"
        "${RED}Fantastic work! You’ve taken a huge leap forward today!${RESET}"
        "${CYAN}You’re on fire! Keep up the great work!${RESET}"
        "${GREEN}Well deserved! Your efforts have led to success!${RESET}"
        "${YELLOW}Incredible! You’ve achieved something special!${RESET}"
        "${BLUE}Outstanding performance! You’re truly excelling!${RESET}"
        "${MAGENTA}Terrific achievement! Keep building on this success!${RESET}"
        "${RED}Bravo! You’ve completed the lab with excellence!${RESET}"
        "${CYAN}Superb job! You’ve shown remarkable focus and effort!${RESET}"
        "${GREEN}Amazing work! You’re making impressive progress!${RESET}"
        "${YELLOW}You nailed it again! Your consistency is paying off!${RESET}"
        "${BLUE}Incredible dedication! Keep pushing forward!${RESET}"
        "${MAGENTA}Excellent work! Your success today is well earned!${RESET}"
        "${RED}You’ve made it! This is a well-deserved victory!${RESET}"
        "${CYAN}Wonderful job! Your passion and hard work are shining through!${RESET}"
        "${GREEN}You’ve done it! Keep up the hard work and success will follow!${RESET}"
        "${YELLOW}Great execution! You’re truly mastering this!${RESET}"
        "${BLUE}Impressive! This is just the beginning of your journey!${RESET}"
        "${MAGENTA}You’ve achieved something great today! Keep it up!${RESET}"
        "${RED}You’ve made remarkable progress! This is just the start!${RESET}"
    )

    RANDOM_INDEX=$((RANDOM % ${#MESSAGES[@]}))
    echo -e "${BOLD}${MESSAGES[$RANDOM_INDEX]}"
}

# Display a random congratulatory message
random_congrats

echo -e "\n"  # Adding one blank line

cd

remove_files() {
    # Loop through all files in the current directory
    for file in *; do
        # Check if the file name starts with "gsp", "arc", or "shell"
        if [[ "$file" == gsp* || "$file" == arc* || "$file" == shell* ]]; then
            # Check if it's a regular file (not a directory)
            if [[ -f "$file" ]]; then
                # Remove the file and echo the file name
                rm "$file"
                echo "File removed: $file"
            fi
        fi
    done
}

remove_files