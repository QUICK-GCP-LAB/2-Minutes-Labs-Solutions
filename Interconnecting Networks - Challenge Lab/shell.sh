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

# Step 1: Set Compute Project, Zone & Region
echo "${BOLD}${BLUE}Setting Compute Project, Zone & Region${RESET}"
export PROJECT_ID=$(gcloud config get-value project)

export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")

export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")

gcloud config set project $PROJECT_ID

# Step 2: Create Hub VPC
echo "${BOLD}${YELLOW}Creating Hub VPC${RESET}"
gcloud compute networks create hub-vpc --subnet-mode=custom

# Step 3: Create Hub Subnet
echo "${BOLD}${MAGENTA}Creating Hub Subnet${RESET}"
gcloud compute networks subnets create hub-subnet \
    --network=hub-vpc \
    --region=$REGION \
    --range=10.0.0.0/24

# Step 4: Create Hub VM
echo "${BOLD}${CYAN}Creating Hub VM${RESET}"
gcloud compute instances create hub-vm \
    --project=$DEVSHELL_PROJECT_ID \
    --zone=$ZONE \
    --machine-type=e2-medium \
    --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=hub-subnet \
    --metadata=startup-script='sudo apt-get install apache2 -y',enable-oslogin=true \
    --maintenance-policy=MIGRATE \
    --provisioning-model=STANDARD \
    --scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/trace.append \
    --create-disk=auto-delete=yes,boot=yes,device-name=hub-vm,image=projects/debian-cloud/global/images/debian-12-bookworm-v20250212,mode=rw,size=10,type=pd-balanced \
    --no-shielded-secure-boot \
    --shielded-vtpm \
    --shielded-integrity-monitoring \
    --labels=goog-ec-src=vm_add-gcloud \
    --reservation-affinity=any 

# Step 5: Create Snapshot Schedule
echo "${BOLD}${RED}Creating Snapshot Schedule${RESET}"
gcloud compute resource-policies create snapshot-schedule default-schedule-1 \
    --project=$DEVSHELL_PROJECT_ID \
    --region=$REGION \
    --max-retention-days=14 \
    --on-source-disk-delete=keep-auto-snapshots \
    --daily-schedule \
    --start-time=06:00 

# Step 6: Attach Snapshot Schedule to Hub VM
echo "${BOLD}${BLUE}Attaching Snapshot Schedule to Hub VM${RESET}"
gcloud compute disks add-resource-policies hub-vm \
    --project=$DEVSHELL_PROJECT_ID \
    --zone=$ZONE \
    --resource-policies=projects/$DEVSHELL_PROJECT_ID/regions/$REGION/resourcePolicies/default-schedule-1

# Step 7: Create Firewall Rules for Hub VPC
echo "${BOLD}${GREEN}Creating Firewall Rules for Hub VPC${RESET}"
gcloud compute firewall-rules create hub-firewall1 \
  --network=hub-vpc \
  --allow=icmp \
  --source-ranges=0.0.0.0/0

gcloud compute firewall-rules create hub-firewall2 \
  --network=hub-vpc \
  --allow=tcp:22 \
  --source-ranges=35.235.240.0/20

# Step 8: Create Hub Instance Group
echo "${BOLD}${YELLOW}Creating Hub Instance Group${RESET}"
gcloud compute instance-groups unmanaged create hub-group \
  --project=$DEVSHELL_PROJECT_ID \
  --zone=$ZONE

# Step 9: Add Hub VM to Instance Group
echo "${BOLD}${MAGENTA}Adding Hub VM to Instance Group${RESET}"
gcloud compute instance-groups unmanaged add-instances hub-group \
  --project=$DEVSHELL_PROJECT_ID \
  --zone=$ZONE \
  --instances=hub-vm

# Step 10: Enable Required Services
echo "${BOLD}${CYAN}Enabling Required Services${RESET}"
gcloud compute networks subnets create pscsubnet \
  --network=hub-vpc \
  --region=$REGION \
  --range=10.1.0.0/24

# Step 11: Enable required Google Cloud services
echo "${BOLD}${RED}Enabling required Google Cloud services...${RESET}"
gcloud services enable networkmanagement.googleapis.com
gcloud services enable osconfig.googleapis.com

# Step 12: Create a connectivity test
echo "${BOLD}${GREEN}Creating a connectivity test...${RESET}"
gcloud beta network-management connectivity-tests create pscservice \
  --destination-ip-address=192.0.2.1 \
  --destination-port=80 \
  --destination-project=$DEVSHELL_PROJECT_ID \
  --protocol=TCP \
  --round-trip \
  --source-instance=projects/$DEVSHELL_PROJECT_ID/zones/$ZONE/instances/hub-vm \
  --source-ip-address=10.0.0.2 \
  --source-network=projects/$DEVSHELL_PROJECT_ID/global/networks/hub-vpc \
  --project=$DEVSHELL_PROJECT_ID

# Step 13: Create spoke1-vpc network
echo "${BOLD}${YELLOW}Creating spoke1-vpc network...${RESET}"
gcloud compute networks create spoke1-vpc \
  --project=$DEVSHELL_PROJECT_ID \
  --subnet-mode=custom \
  --mtu=1460 \
  --bgp-routing-mode=regional \
  --bgp-best-path-selection-mode=legacy

# Step 14: Create spoke1-subnet
echo "${BOLD}${BLUE}Creating spoke1-subnet...${RESET}"
gcloud compute networks subnets create spoke1-subnet \
  --project=$DEVSHELL_PROJECT_ID \
  --range=10.1.1.0/24 \
  --stack-type=IPV4_ONLY \
  --network=spoke1-vpc \
  --region=$REGION

# Step 15: Waiting for resources to stabilize
echo "${BOLD}${MAGENTA}Waiting 15 seconds for resources to be ready...${RESET}"
sleep 15

# Step 16: Create spoke1-vm
echo "${BOLD}${CYAN}Creating spoke1-vm...${RESET}"
gcloud compute instances create spoke1-vm \
  --zone=$ZONE \
  --subnet=spoke1-subnet \
  --image=projects/debian-cloud/global/images/debian-12-bookworm-v20250212 \
  --tags=http-server

# Step 17: Create firewall rules for spoke1-vpc
echo "${BOLD}${RED}Creating firewall rules for spoke1-vpc...${RESET}"
gcloud compute firewall-rules create spoke1-firewall1 \
  --network=spoke1-vpc \
  --allow=icmp \
  --source-ranges=0.0.0.0/0

gcloud compute firewall-rules create spoke1-firewall2 \
  --network=spoke1-vpc \
  --allow=tcp:22 \
  --source-ranges=35.235.240.0/20

# Step 18: Create peering between hub-vpc and spoke1-vpc
echo "${BOLD}${GREEN}Creating VPC peering between hub-vpc and spoke1-vpc...${RESET}"
gcloud compute networks peerings create hub-spoke1 \
  --network=hub-vpc \
  --peer-network=spoke1-vpc \
  --auto-create-routes

gcloud compute networks peerings create spoke1-hub \
  --network=spoke1-vpc \
  --peer-network=hub-vpc

# Step 19: Create spoke2-vpc network
echo "${BOLD}${YELLOW}Creating spoke2-vpc network...${RESET}"
gcloud compute networks create spoke2-vpc \
  --project=$DEVSHELL_PROJECT_ID \
  --subnet-mode=custom \
  --mtu=1460 \
  --bgp-routing-mode=regional \
  --bgp-best-path-selection-mode=legacy

# Step 20: Create spoke2-subnet
echo "${BOLD}${BLUE}Creating spoke2-subnet...${RESET}"
gcloud compute networks subnets create spoke2-subnet \
  --project=$DEVSHELL_PROJECT_ID \
  --range=10.2.1.0/24 \
  --stack-type=IPV4_ONLY \
  --network=spoke2-vpc \
  --region=$REGION

# Step 21: Create firewall rules for spoke2-vpc
echo "${BOLD}${MAGENTA}Creating firewall rules for spoke2-vpc...${RESET}"
gcloud compute firewall-rules create spoke2-firewall1 \
  --project=$DEVSHELL_PROJECT_ID \
  --direction=INGRESS \
  --priority=1000 \
  --network=spoke2-vpc \
  --action=ALLOW \
  --rules=icmp \
  --source-ranges=0.0.0.0/0

gcloud compute firewall-rules create spoke2-firewall2 \
  --project=$DEVSHELL_PROJECT_ID \
  --direction=INGRESS \
  --priority=1000 \
  --network=spoke2-vpc \
  --action=ALLOW \
  --rules=tcp:22 \
  --source-ranges=35.235.240.0/20

# Step 22: Create spoke2 VM instance
echo "${BOLD}${RED}Creating spoke2 VM instance...${RESET}"
gcloud compute instances create spoke2-vm \
  --project=$DEVSHELL_PROJECT_ID \
  --zone=$ZONE \
  --machine-type=e2-medium \
  --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=spoke2-subnet \
  --metadata=enable-osconfig=TRUE,enable-oslogin=true \
  --maintenance-policy=MIGRATE \
  --provisioning-model=STANDARD \
  --scopes=https://www.googleapis.com/auth/devstorage.read_only,\
https://www.googleapis.com/auth/logging.write,\
https://www.googleapis.com/auth/monitoring.write,\
https://www.googleapis.com/auth/service.management.readonly,\
https://www.googleapis.com/auth/servicecontrol,\
https://www.googleapis.com/auth/trace.append \
  --create-disk=auto-delete=yes,boot=yes,device-name=spoke2-vm,\
disk-resource-policy=projects/$DEVSHELL_PROJECT_ID/regions/$REGION/resourcePolicies/default-schedule-1,\
image=projects/debian-cloud/global/images/debian-12-bookworm-v20250212,\
mode=rw,size=10,type=pd-balanced \
  --no-shielded-secure-boot \
  --shielded-vtpm \
  --shielded-integrity-monitoring \
  --labels=goog-ops-agent-policy=v2-x86-template-1-4-0,goog-ec-src=vm_add-gcloud \
  --reservation-affinity=any

# Step 23: Create configuration file for Ops Agent
echo "${BOLD}${BLUE}Creating Ops Agent configuration file...${RESET}"
printf 'agentsRule:\n  packageState: installed\n  version: latest\ninstanceFilter:\n  inclusionLabels:\n  - labels:\n      goog-ops-agent-policy: v2-x86-template-1-4-0\n' > config.yaml

# Step 24: Create Ops Agent policy
echo "${BOLD}${MAGENTA}Creating Ops Agent policy...${RESET}"
gcloud compute instances ops-agents policies create goog-ops-agent-v2-x86-template-1-4-0-$ZONE \
  --project=$DEVSHELL_PROJECT_ID \
  --zone=$ZONE \
  --file=config.yaml

# Step 25: Create spoke3 VPC
echo "${BOLD}${CYAN}Creating spoke3 VPC...${RESET}"
gcloud compute networks create spoke3-vpc \
  --project=$DEVSHELL_PROJECT_ID \
  --subnet-mode=custom \
  --mtu=1460 \
  --bgp-routing-mode=regional \
  --bgp-best-path-selection-mode=legacy

# Step 26: Create spoke3 subnet
echo "${BOLD}${YELLOW}Creating spoke3 subnet...${RESET}"
gcloud compute networks subnets create spoke3-subnet \
  --project=$DEVSHELL_PROJECT_ID \
  --range=10.3.1.0/24 \
  --stack-type=IPV4_ONLY \
  --network=spoke3-vpc \
  --region=$REGION

# Step 27: Create spoke3 firewall rule for ICMP
echo "${BOLD}${GREEN}Creating spoke3 firewall rule for ICMP...${RESET}"
gcloud compute firewall-rules create spoke3-firewall1 \
  --project=$DEVSHELL_PROJECT_ID \
  --direction=INGRESS \
  --priority=1000 \
  --network=spoke3-vpc \
  --action=ALLOW \
  --rules=icmp \
  --source-ranges=0.0.0.0/0

# Step 28: Create spoke3 firewall rule for SSH
echo "${BOLD}${RED}Creating spoke3 firewall rule for SSH...${RESET}"
gcloud compute firewall-rules create spoke3-firewall2 \
  --project=$DEVSHELL_PROJECT_ID \
  --direction=INGRESS \
  --priority=1000 \
  --network=spoke3-vpc \
  --action=ALLOW \
  --rules=tcp:22 \
  --source-ranges=35.235.240.0/20

# Step 29: Create spoke3 VM instance
echo "${BOLD}${CYAN}Creating spoke3 VM instance...${RESET}"
gcloud compute instances create spoke3-vm \
  --project=$DEVSHELL_PROJECT_ID \
  --zone=$ZONE \
  --machine-type=e2-medium \
  --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=spoke3-subnet \
  --metadata=enable-osconfig=TRUE,enable-oslogin=true \
  --maintenance-policy=MIGRATE \
  --provisioning-model=STANDARD \
  --scopes=https://www.googleapis.com/auth/devstorage.read_only,\
https://www.googleapis.com/auth/logging.write,\
https://www.googleapis.com/auth/monitoring.write,\
https://www.googleapis.com/auth/service.management.readonly,\
https://www.googleapis.com/auth/servicecontrol,\
https://www.googleapis.com/auth/trace.append \
  --create-disk=auto-delete=yes,boot=yes,device-name=spoke3-vm,\
disk-resource-policy=projects/$DEVSHELL_PROJECT_ID/regions/$REGION/resourcePolicies/default-schedule-1,\
image=projects/debian-cloud/global/images/debian-12-bookworm-v20250212,\
mode=rw,size=10,type=pd-balanced \
  --no-shielded-secure-boot \
  --shielded-vtpm \
  --shielded-integrity-monitoring \
  --labels=goog-ops-agent-policy=v2-x86-template-1-4-0,goog-ec-src=vm_add-gcloud \
  --reservation-affinity=any

# Step 30: Create VPN Gateways
echo "${BOLD}${CYAN}Creating VPN gateways${RESET}"
gcloud compute vpn-gateways create hub-gateway \
  --region=$REGION \
  --network=hub-vpc

gcloud compute vpn-gateways create spoke2-gateway \
  --region=$REGION \
  --network=spoke2-vpc

gcloud compute vpn-gateways create spoke3-gateway \
  --region=$REGION \
  --network=spoke3-vpc

# Step 31: Create Routers
echo "${BOLD}${MAGENTA}Creating Routers${RESET}"
gcloud compute routers create hub-router \
  --region=$REGION \
  --network=hub-vpc \
  --asn=65000

gcloud compute routers create spoke2-router \
  --region=$REGION \
  --network=spoke2-vpc \
  --asn=65002

gcloud compute routers create spoke3-router \
  --region=$REGION \
  --network=spoke3-vpc \
  --asn 65003

# Step 32: Create VPN Tunnels
echo "${BOLD}${BLUE}Creating VPN tunnels${RESET}"
gcloud compute vpn-tunnels create tun-hub-spoke2-1 \
  --region=$REGION \
  --peer-gcp-gateway=spoke2-gateway \
  --ike-version=2 \
  --shared-secret=[SHARED_SECRET] \
  --vpn-gateway=hub-gateway \
  --interface=0 \
  --router=hub-router

gcloud compute vpn-tunnels create tun-spoke2-hub-1 \
  --region=$REGION \
  --peer-gcp-gateway=hub-gateway \
  --ike-version=2 \
  --shared-secret=[SHARED_SECRET] \
  --vpn-gateway=spoke2-gateway \
  --interface=0 \
  --router=spoke2-router

gcloud compute vpn-tunnels create tun-hub-spoke3-1 \
  --region=$REGION \
  --peer-gcp-gateway=spoke3-gateway \
  --ike-version=2 \
  --shared-secret=[SHARED_SECRET] \
  --vpn-gateway=hub-gateway \
  --interface=0 \
  --router=hub-router

gcloud compute vpn-tunnels create tun-spoke3-hub-1 \
  --region=$REGION \
  --peer-gcp-gateway=hub-gateway \
  --ike-version=2 \
  --shared-secret=[SHARED_SECRET] \
  --vpn-gateway=spoke3-gateway \
  --interface=0 \
  --router=spoke3-router

# Step 33: Create Connectivity Hub
echo "${BOLD}${RED}Creating Network Connectivity Hub${RESET}"
gcloud network-connectivity hubs create hub-23

gcloud network-connectivity spokes linked-vpn-tunnels create hubspoke2 \
  --hub=hub-23 \
  --vpn-tunnels=tun-hub-spoke2-1 \
  --region=$REGION \
  --site-to-site-data-transfer

gcloud network-connectivity spokes linked-vpn-tunnels create hubspoke3 \
  --hub=hub-23 \
  --vpn-tunnels=tun-hub-spoke3-1 \
  --region=$REGION \
  --site-to-site-data-transfer

# Step 34: Delete default firewall rules and network
echo "${BOLD}${YELLOW}Deleting default firewall rules and network${RESET}"
gcloud compute firewall-rules delete $(gcloud compute firewall-rules list \
  --filter="network:default" --format="value(name)") --quiet

gcloud compute networks delete default --quiet

# Step 35: Create spoke4-vpc network
echo "${BOLD}${GREEN}Creating spoke4-vpc network${RESET}"
gcloud compute networks create spoke4-vpc \
  --project=$DEVSHELL_PROJECT_ID \
  --subnet-mode=custom \
  --mtu=1460 \
  --bgp-routing-mode=regional \
  --bgp-best-path-selection-mode=legacy

# Step 36: Create Spoke4 subnet
echo "${BOLD}${CYAN}Creating spoke4-subnet${RESET}"
gcloud compute networks subnets create spoke4-subnet \
  --project=$DEVSHELL_PROJECT_ID \
  --range=10.4.1.0/24 \
  --stack-type=IPV4_ONLY \
  --network=spoke4-vpc \
  --region=$REGION

# Step 37: Create spoke4 firewall
echo "${BOLD}${CYAN}Creating spoke4-firewall${RESET}"
gcloud compute firewall-rules create spoke4-firewall \
  --network=spoke4-vpc \
  --allow=tcp:22 \
  --source-ranges=35.235.240.0/20

# Step 38: Create Spoke4 VM
echo "${BOLD}${MAGENTA}Creating spoke4-vm instance${RESET}"
gcloud compute instances create spoke4-vm \
  --project=$DEVSHELL_PROJECT_ID \
  --zone=$ZONE \
  --machine-type=e2-medium \
  --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=spoke4-subnet \
  --metadata=enable-osconfig=TRUE,enable-oslogin=true \
  --maintenance-policy=MIGRATE \
  --provisioning-model=STANDARD \
  --scopes=https://www.googleapis.com/auth/devstorage.read_only,\
https://www.googleapis.com/auth/logging.write,\
https://www.googleapis.com/auth/monitoring.write,\
https://www.googleapis.com/auth/service.management.readonly,\
https://www.googleapis.com/auth/servicecontrol,\
https://www.googleapis.com/auth/trace.append \
  --create-disk=auto-delete=yes,boot=yes,device-name=spoke4-vm,\
image=projects/debian-cloud/global/images/debian-12-bookworm-v20250212,\
mode=rw,size=10,type=pd-balanced \
  --no-shielded-secure-boot \
  --shielded-vtpm \
  --shielded-integrity-monitoring \
  --labels=goog-ops-agent-policy=v2-x86-template-1-4-0,goog-ec-src=vm_add-gcloud \
  --reservation-affinity=any

# Step 39: Create connectivity test
echo "${BOLD}${RED}Creating connectivity test between spoke1 and hub${RESET}"
gcloud beta network-management connectivity-tests create test-spoke1-hub \
  --destination-instance=projects/$DEVSHELL_PROJECT_ID/zones/$ZONE/instances/hub-vm \
  --destination-network=projects/$DEVSHELL_PROJECT_ID/global/networks/hub-vpc \
  --destination-port=80 \
  --protocol=TCP \
  --round-trip \
  --source-instance=projects/$DEVSHELL_PROJECT_ID/zones/$ZONE/instances/spoke1-vm \
  --source-ip-address=10.1.1.2 \
  --source-network=projects/$DEVSHELL_PROJECT_ID/global/networks/spoke1-vpc \
  --project=$DEVSHELL_PROJECT_ID

# Step 40: Create connectivity test between spoke2 and hub
echo "${BOLD}${CYAN}Creating connectivity test: spoke2 to hub${RESET}"
gcloud beta network-management connectivity-tests create test-spoke2-hub \
  --destination-instance=projects/$DEVSHELL_PROJECT_ID/zones/$ZONE/instances/hub-vm \
  --destination-network=projects/$DEVSHELL_PROJECT_ID/global/networks/hub-vpc \
  --destination-port=80 \
  --protocol=TCP \
  --round-trip \
  --source-instance=projects/$DEVSHELL_PROJECT_ID/zones/$ZONE/instances/spoke2-vm \
  --source-ip-address=10.2.1.2 \
  --source-network=projects/$DEVSHELL_PROJECT_ID/global/networks/spoke2-vpc \
  --project=$DEVSHELL_PROJECT_ID

# Step 41: Create connectivity test between spoke3 and hub
echo "${BOLD}${YELLOW}Creating connectivity test: spoke3 to hub${RESET}"
gcloud beta network-management connectivity-tests create test-spoke3-hub \
  --destination-instance=projects/$DEVSHELL_PROJECT_ID/zones/$ZONE/instances/hub-vm \
  --destination-network=projects/$DEVSHELL_PROJECT_ID/global/networks/hub-vpc \
  --destination-port=80 \
  --protocol=TCP \
  --round-trip \
  --source-instance=projects/$DEVSHELL_PROJECT_ID/zones/$ZONE/instances/spoke3-vm \
  --source-ip-address=10.3.1.2 \
  --source-network=projects/$DEVSHELL_PROJECT_ID/global/networks/spoke3-vpc \
  --project=$DEVSHELL_PROJECT_ID

# Step 42: Create connectivity test between spoke2 and spoke3
echo "${BOLD}${MAGENTA}Creating connectivity test: spoke2 to spoke3${RESET}"
gcloud beta network-management connectivity-tests create test-spoke2-spoke3 \
  --destination-instance=projects/$DEVSHELL_PROJECT_ID/zones/$ZONE/instances/spoke3-vm \
  --destination-network=projects/$DEVSHELL_PROJECT_ID/global/networks/spoke3-vpc \
  --destination-port=80 \
  --protocol=TCP \
  --round-trip \
  --source-instance=projects/$DEVSHELL_PROJECT_ID/zones/$ZONE/instances/spoke2-vm \
  --source-ip-address=10.2.1.2 \
  --source-network=projects/$DEVSHELL_PROJECT_ID/global/networks/spoke2-vpc \
  --project=$DEVSHELL_PROJECT_ID

# Step 43: Create connectivity test between spoke4 and hub
echo "${BOLD}${MAGENTA}Creating connectivity test: spoke4 to hub${RESET}"
gcloud beta network-management connectivity-tests create test-spoke4-hub \
  --destination-instance=projects/$DEVSHELL_PROJECT_ID/zones/$ZONE/instances/hub-vm \
  --destination-network=projects/$DEVSHELL_PROJECT_ID/global/networks/hub-vpc \
  --destination-port=80 \
  --protocol=TCP \
  --round-trip \
  --source-instance=projects/$DEVSHELL_PROJECT_ID/zones/$ZONE/instances/spoke4-vm \
  --source-ip-address=10.4.1.2 \
  --source-network=projects/$DEVSHELL_PROJECT_ID/global/networks/spoke4-vpc \
  --project=$DEVSHELL_PROJECT_ID

# Step 44: Create subnet for spoke4
echo "${BOLD}${BLUE}Creating subnet: pscsubnet-spoke4${RESET}"
gcloud compute networks subnets create pscsubnet-spoke4 \
  --network=spoke4-vpc \
  --region=$REGION \
  --range=10.4.2.0/24

# Step 45: Create subnet for hub
echo "${BOLD}${RED}Creating subnet: pscsubnet-hub${RESET}"
gcloud compute networks subnets create pscsubnet-hub \
  --network=hub-vpc \
  --region=$REGION \
  --range=10.4.3.0/24

# Step 46: Create PSC service
echo "${BOLD}${RED}Creating PSC service: pscservice${RESET}"
gcloud beta network-management connectivity-tests create pscservice-test \
  --destination-ip-address=192.0.2.1 \
  --destination-port=80 \
  --destination-project=$DEVSHELL_PROJECT_ID \
  --protocol=TCP \
  --round-trip \
  --source-instance=projects/$DEVSHELL_PROJECT_ID/zones/$ZONE/instances/hub-vm \
  --source-ip-address=10.4.1.2 \
  --source-network=projects/$DEVSHELL_PROJECT_ID/global/networks/hub-vpc \
  --project=$DEVSHELL_PROJECT_ID

# Step 47: Create health check
echo "${BOLD}${CYAN}Creating health check: hub-health-check${RESET}"
gcloud compute health-checks create tcp hub-health-check \
    --port=80 \
    --global

# Step 48: Create backend service
echo "${BOLD}${YELLOW}Creating backend service: hub-backend-service${RESET}"
gcloud compute backend-services create hub-backend-service \
    --load-balancing-scheme=INTERNAL \
    --protocol=TCP \
    --region=$REGION \
    --health-checks=hub-health-check \
    --network=hub-vpc

# Step 49: Create forwarding rule
echo "${BOLD}${MAGENTA}Creating forwarding rule: hub-ilb${RESET}"
gcloud compute forwarding-rules create hub-ilb \
    --region=$REGION \
    --load-balancing-scheme=INTERNAL \
    --network=hub-vpc \
    --subnet=pscsubnet-hub \
    --ip-protocol=TCP \
    --ports=80 \
    --backend-service=hub-backend-service \
    --allow-global-access

# Step 50: Create PSC subnet for hub
echo "${BOLD}${BLUE}Creating PSC subnet: psc-subnet-hub${RESET}"
gcloud compute networks subnets create psc-subnet-hub \
    --region=$REGION \
    --network=hub-vpc \
    --range=10.10.10.0/24 \
    --purpose=PRIVATE_SERVICE_CONNECT

# Step 51: Create PSC service
echo "${BOLD}${RED}Creating PSC service: pscservice${RESET}"
gcloud compute service-attachments create pscservice \
    --region=$REGION \
    --producer-forwarding-rule=hub-ilb \
    --nat-subnets=psc-subnet-hub \
    --connection-preference=ACCEPT_AUTOMATIC

# Step 52: Create PSC endpoint IP
echo "${BOLD}${CYAN}Creating PSC endpoint IP${RESET}"
gcloud compute addresses create psc-endpoint-ip \
    --region=$REGION \
    --subnet=pscsubnet-spoke4 \
    --addresses=10.4.1.10

# Step 53: Create PSC endpoint
echo "${BOLD}${YELLOW}Creating PSC endpoint${RESET}"
gcloud compute forwarding-rules create pscendpoint \
    --region=$REGION \
    --network=spoke4-vpc \
    --subnet=pscsubnet-spoke4 \
    --target-service-attachment="https://www.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/regions/$REGION/serviceAttachments/pscservice" \
    --address=psc-endpoint-ip

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
    echo "${BOLD}${MESSAGES[$RANDOM_INDEX]}"
}

# Display a random congratulatory message
random_congrats

echo "\n"  # Adding one blank line

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