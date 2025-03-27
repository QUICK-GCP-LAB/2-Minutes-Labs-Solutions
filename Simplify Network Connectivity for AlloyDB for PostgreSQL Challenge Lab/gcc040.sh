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

# Step 1: Get Variables
echo "${BOLD}${GREEN}Getting Variables${RESET}"

set_variables() {
    while true; do
        echo
        echo -n "${BOLD}${YELLOW}Enter your CLUSTER_ID: ${RESET}"
        read -r CLUSTER_ID

        echo
        echo -n "${BOLD}${MAGENTA}Enter your PASSWORD: ${RESET}"
        read -r PASSWORD

        if [[ -z "$CLUSTER_ID" || -z "$PASSWORD" ]]; then
            echo
            echo "${BOLD}${RED}Neither CLUSTER_ID nor PASSWORD can be empty. Please enter valid values.${RESET}"
            echo
        else
            export CLUSTER_ID="$CLUSTER_ID"
            export PASSWORD="$PASSWORD"
            export INSTANCE_ID="${CLUSTER_ID/cluster/instance}"
            echo
            break
        fi
    done
}

# Call function to get input from user
set_variables

# Step 2: Set Compute Zone & Region
echo "${BOLD}${BLUE}Setting Compute Zone & Region${RESET}"
export PROJECT_ID=$(gcloud config get-value project)

export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")

export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")

gcloud config set compute/region $REGION

# Step 3: Create PSA Range
echo "${BOLD}${CYAN}Creating PSA Range${RESET}"
gcloud compute addresses create psa-range \
    --global \
    --purpose=VPC_PEERING \
    --addresses=10.8.12.0 \
    --prefix-length=24 \
    --network=cloud-vpc

sleep 30

# Step 4: Establish VPC Peering
echo "${BOLD}${MAGENTA}Establishing VPC Peering${RESET}"
gcloud services vpc-peerings connect \
    --service=servicenetworking.googleapis.com \
    --network=cloud-vpc \
    --ranges=psa-range

gcloud compute networks peerings update servicenetworking-googleapis-com \
    --network=cloud-vpc \
    --export-custom-routes \
    --import-custom-routes

# Step 5: Create AlloyDB Cluster & Instance
echo "${BOLD}${YELLOW}Creating AlloyDB Cluster & Instance${RESET}"
gcloud alloydb clusters create $CLUSTER_ID \
    --region=$REGION \
    --network=cloud-vpc \
    --password=$PASSWORD \
    --allocated-ip-range-name=psa-range

gcloud alloydb instances create $INSTANCE_ID \
    --region=$REGION \
    --cluster=$CLUSTER_ID \
    --instance-type=PRIMARY \
    --cpu-count=2

# Step 6: Create VPN Gateways
echo "${BOLD}${GREEN}Creating VPN Gateways${RESET}"
gcloud beta compute vpn-gateways create cloud-vpc-vpn-gw1 --network cloud-vpc --region "$REGION"
gcloud beta compute vpn-gateways create on-prem-vpn-gw1 --network on-prem-vpc --region "$REGION"

# Step 7: Describe VPN Gateways
echo "${BOLD}${CYAN}Describing VPN Gateways${RESET}"
gcloud beta compute vpn-gateways describe cloud-vpc-vpn-gw1 --region "$REGION"

gcloud beta compute vpn-gateways describe on-prem-vpn-gw1 --region "$REGION"

# Step 8: Create Routers
echo "${BOLD}${MAGENTA}Creating Routers${RESET}"
gcloud compute routers create cloud-vpc-router1 \
    --region "$REGION" \
    --network cloud-vpc \
    --asn 65001

gcloud compute routers create on-prem-vpc-router1 \
    --region "$REGION" \
    --network on-prem-vpc \
    --asn 65002

# Step 9: Create VPN Tunnels
echo "${BOLD}${YELLOW}Creating VPN Tunnels${RESET}"
gcloud beta compute vpn-tunnels create cloud-vpc-tunnel0 \
    --peer-gcp-gateway on-prem-vpn-gw1 \
    --region "$REGION" \
    --ike-version 2 \
    --shared-secret [SHARED_SECRET] \
    --router cloud-vpc-router1 \
    --vpn-gateway cloud-vpc-vpn-gw1 \
    --interface 0

gcloud beta compute vpn-tunnels create cloud-vpc-tunnel1 \
    --peer-gcp-gateway on-prem-vpn-gw1 \
    --region "$REGION" \
    --ike-version 2 \
    --shared-secret [SHARED_SECRET] \
    --router cloud-vpc-router1 \
    --vpn-gateway cloud-vpc-vpn-gw1 \
    --interface 1

gcloud beta compute vpn-tunnels create on-prem-vpc-tunnel0 \
    --peer-gcp-gateway cloud-vpc-vpn-gw1 \
    --region "$REGION" \
    --ike-version 2 \
    --shared-secret [SHARED_SECRET] \
    --router on-prem-vpc-router1 \
    --vpn-gateway on-prem-vpn-gw1 \
    --interface 0

gcloud beta compute vpn-tunnels create on-prem-vpc-tunnel1 \
    --peer-gcp-gateway cloud-vpc-vpn-gw1 \
    --region "$REGION" \
    --ike-version 2 \
    --shared-secret [SHARED_SECRET] \
    --router on-prem-vpc-router1 \
    --vpn-gateway on-prem-vpn-gw1 \
    --interface 1

# Step 10: Add Router Interfaces
echo "${BOLD}${BLUE}Adding Router Interfaces${RESET}"
gcloud compute routers add-interface cloud-vpc-router1 \
    --interface-name if-tunnel0-to-on-prem-vpc \
    --ip-address 169.254.0.1 \
    --mask-length 30 \
    --vpn-tunnel cloud-vpc-tunnel0 \
    --region "$REGION"

# Step 11: Configure BGP Peering
echo "${BOLD}${CYAN}Configuring BGP Peering${RESET}"
gcloud compute routers add-bgp-peer cloud-vpc-router1 \
    --peer-name bgp-on-prem-tunnel0 \
    --interface if-tunnel0-to-on-prem-vpc \
    --peer-ip-address 169.254.0.2 \
    --peer-asn 65002 \
    --region "$REGION"

# Step 12: Add Router Interfaces
echo "${BOLD}${BLUE}Adding Router Interfaces${RESET}"
gcloud compute routers add-interface cloud-vpc-router1 \
    --interface-name if-tunnel1-to-on-prem-vpc \
    --ip-address 169.254.1.1 \
    --mask-length 30 \
    --vpn-tunnel cloud-vpc-tunnel1 \
    --region "$REGION"

# Step 13: Configure BGP Peering
echo "${BOLD}${CYAN}Configuring BGP Peering${RESET}"
gcloud compute routers add-bgp-peer cloud-vpc-router1 \
    --peer-name bgp-on-prem-vpc-tunnel1 \
    --interface if-tunnel1-to-on-prem-vpc \
    --peer-ip-address 169.254.1.2 \
    --peer-asn 65002 \
    --region "$REGION"

# Step 14: Add Router Interfaces
echo "${BOLD}${BLUE}Adding Router Interfaces${RESET}"
gcloud compute routers add-interface on-prem-vpc-router1 \
    --interface-name if-tunnel0-to-cloud-vpc \
    --ip-address 169.254.0.2 \
    --mask-length 30 \
    --vpn-tunnel on-prem-vpc-tunnel0 \
    --region "$REGION"

# Step 15: Configure BGP Peering
echo "${BOLD}${CYAN}Configuring BGP Peering${RESET}"
gcloud compute routers add-bgp-peer on-prem-vpc-router1 \
    --peer-name bgp-cloud-vpc-tunnel0 \
    --interface if-tunnel0-to-cloud-vpc \
    --peer-ip-address 169.254.0.1 \
    --peer-asn 65001 \
    --region "$REGION"

# Step 16: Add Router Interfaces
echo "${BOLD}${BLUE}Adding Router Interfaces${RESET}"
gcloud compute routers add-interface on-prem-vpc-router1 \
    --interface-name if-tunnel1-to-cloud-vpc \
    --ip-address 169.254.1.2 \
    --mask-length 30 \
    --vpn-tunnel on-prem-vpc-tunnel1 \
    --region "$REGION"

# Step 17: Configure BGP Peering
echo "${BOLD}${CYAN}Configuring BGP Peering${RESET}"
gcloud compute routers add-bgp-peer on-prem-vpc-router1 \
    --peer-name bgp-cloud-vpc-tunnel1 \
    --interface if-tunnel1-to-cloud-vpc \
    --peer-ip-address 169.254.1.1 \
    --peer-asn 65001 \
    --region "$REGION"

# Step 18: Create firewall rule for cloud-vpc
echo "${BOLD}${GREEN}Creating firewall rule for cloud-vpc${RESET}"
gcloud compute firewall-rules create vpc-demo-allow-subnets-from-on-prem \
    --network cloud-vpc \
    --allow tcp,udp,icmp \
    --source-ranges 192.168.1.0/24

# Step 19: Create firewall rule for on-prem-vpc
echo "${BOLD}${CYAN}Creating firewall rule for on-prem-vpc${RESET}"
gcloud compute firewall-rules create on-prem-allow-subnets-from-vpc-demo \
    --network on-prem-vpc \
    --allow tcp,udp,icmp \
    --source-ranges 10.1.1.0/24,10.2.1.0/24

# Step 20: Update cloud-vpc BGP routing mode
echo "${BOLD}${YELLOW}Updating cloud-vpc BGP routing mode${RESET}"
gcloud compute networks update cloud-vpc --bgp-routing-mode GLOBAL

# Step 21: Create AlloyDB custom route
echo "${BOLD}${MAGENTA}Creating AlloyDB custom route${RESET}"
gcloud compute routes create alloydb-custom-route \
    --network=on-prem-vpc \
    --destination-range=10.8.12.0/24 \
    --next-hop-vpn-tunnel=on-prem-vpc-tunnel0 \
    --priority=1000

# Step 22: Create AlloyDB return route
echo "${BOLD}${BLUE}Creating AlloyDB return route${RESET}"
gcloud compute routes create alloydb-return-route \
    --network=cloud-vpc \
    --destination-range=10.1.1.0/24 \
    --next-hop-vpn-tunnel=cloud-vpc-tunnel0 \
    --priority=1000

# Step 23: Describe AlloyDB instance
echo "${BOLD}${RED}Describing AlloyDB instance${RESET}"
gcloud alloydb instances describe $INSTANCE_ID --region=$REGION --cluster=$CLUSTER_ID

# Step 24: Get AlloyDB IP dynamically
echo "${BOLD}${GREEN}Fetching AlloyDB IP address${RESET}"
export ALLOYDB_IP=$(gcloud alloydb instances describe $INSTANCE_ID --region=$REGION --cluster=$CLUSTER_ID --format='value(ipAddress)')

# Step 25: Execute SQL commands on AlloyDB
echo "${BOLD}${CYAN}Executing SQL commands on AlloyDB via SSH${RESET}"
gcloud compute ssh cloud-vm --zone=$ZONE --quiet --command="bash -c '
export PGPASSWORD=\"$PASSWORD\"
psql -h $ALLOYDB_IP -U postgres -d postgres <<EOF
CREATE TABLE IF NOT EXISTS patients (
    patient_id INT PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    date_of_birth DATE,
    medical_record_number VARCHAR(100) UNIQUE,
    last_visit_date DATE,
    primary_physician VARCHAR(100)
);

INSERT INTO patients (patient_id, first_name, last_name, date_of_birth, medical_record_number, last_visit_date, primary_physician)
VALUES 
(1, \"John\", \"Doe\", \"1985-07-12\", \"MRN123456\", \"2024-02-20\", \"Dr. Smith\"),
(2, \"Jane\", \"Smith\", \"1990-11-05\", \"MRN654321\", \"2024-02-25\", \"Dr. Johnson\")
ON CONFLICT (patient_id) DO NOTHING;

CREATE TABLE IF NOT EXISTS clinical_trials (
    trial_id INT PRIMARY KEY,
    trial_name VARCHAR(100),
    start_date DATE,
    end_date DATE,
    lead_researcher VARCHAR(100),
    number_of_participants INT,
    trial_status VARCHAR(20)
);

INSERT INTO clinical_trials (trial_id, trial_name, start_date, end_date, lead_researcher, number_of_participants, trial_status)
VALUES 
    (1, \"Trial A\", \"2025-01-01\", \"2025-12-31\", \"Dr. John Doe\", 200, \"Ongoing\"),
    (2, \"Trial B\", \"2025-02-01\", \"2025-11-30\", \"Dr. Jane Smith\", 150, \"Completed\")
ON CONFLICT (trial_id) DO NOTHING;

SELECT * FROM patients;
SELECT * FROM clinical_trials;
EOF
'"

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