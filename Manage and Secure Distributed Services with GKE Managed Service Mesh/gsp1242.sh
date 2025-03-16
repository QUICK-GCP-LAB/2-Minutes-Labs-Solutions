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

# Step 1: Fetching project default zone
echo "${GREEN}${BOLD}Fetching project default zone...${RESET}"
export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")

# Step 2: Fetching project default region
echo "${CYAN}${BOLD}Fetching project default region...${RESET}"
export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")

# Step 3: Enabling required Google Cloud services
echo "${MAGENTA}${BOLD}Enabling required Google Cloud services...${RESET}"
gcloud services enable \
--project=$DEVSHELL_PROJECT_ID \
container.googleapis.com \
mesh.googleapis.com \
gkehub.googleapis.com

# Step 4: Enabling fleet mesh
echo "${YELLOW}${BOLD}Enabling fleet mesh...${RESET}"
gcloud container fleet mesh enable --project=$DEVSHELL_PROJECT_ID

# Step 5: Creating NAT IP address
echo "${BLUE}${BOLD}Creating NAT IP address...${RESET}"
gcloud compute addresses create $REGION-nat-ip \
  --project=$DEVSHELL_PROJECT_ID \
  --region=$REGION

# Step 6: Fetching NAT IP details
echo "${RED}${BOLD}Fetching NAT IP details...${RESET}"
export NAT_REGION_1_IP_ADDR=$(gcloud compute addresses describe $REGION-nat-ip \
  --project=$DEVSHELL_PROJECT_ID \
  --region=$REGION \
  --format='value(address)')

export NAT_REGION_1_IP_NAME=$(gcloud compute addresses describe $REGION-nat-ip \
  --project=$DEVSHELL_PROJECT_ID \
  --region=$REGION \
  --format='value(name)')

gcloud compute routers create rtr-$REGION \
  --network=default \
  --region $REGION

gcloud compute routers nats create nat-gw-$REGION \
  --router=rtr-$REGION \
  --region $REGION \
  --nat-external-ip-pool=${NAT_REGION_1_IP_NAME} \
  --nat-all-subnet-ip-ranges \
  --enable-logging

# Step 9: Creating firewall rule
echo "${MAGENTA}${BOLD}Creating firewall rule...${RESET}"
gcloud compute firewall-rules create all-pods-and-master-ipv4-cidrs \
  --project $DEVSHELL_PROJECT_ID \
  --network default \
  --allow all \
  --direction INGRESS \
  --source-ranges 172.16.0.0/28,172.16.1.0/28,172.16.2.0/28,0.0.0.0/0

# Step 10: Fetching CloudShell and Lab VM IPs
echo "${YELLOW}${BOLD}Fetching CloudShell and Lab VM IPs...${RESET}"
export CLOUDSHELL_IP=$(dig +short myip.opendns.com @resolver1.opendns.com)
export LAB_VM_IP=$(gcloud compute instances describe lab-setup --format='get(networkInterfaces[0].accessConfigs[0].natIP)' --zone=$ZONE)

# Step 11: Creating Kubernetes cluster1
echo "${BLUE}${BOLD}Creating Kubernetes cluster1...${RESET}"
gcloud container clusters create cluster1 \
  --project $DEVSHELL_PROJECT_ID \
  --zone=$ZONE \
  --machine-type "e2-standard-4" \
  --num-nodes "2" --min-nodes "2" --max-nodes "2" \
  --enable-ip-alias --enable-autoscaling \
  --workload-pool=$DEVSHELL_PROJECT_ID.svc.id.goog \
  --enable-private-nodes \
  --master-ipv4-cidr=172.16.0.0/28 \
  --enable-master-authorized-networks \
  --master-authorized-networks $NAT_REGION_1_IP_ADDR/32,$CLOUDSHELL_IP/32,$LAB_VM_IP/32 --async

# Step 12: Creating Kubernetes cluster2
echo "${RED}${BOLD}Creating Kubernetes cluster2...${RESET}"
gcloud container clusters create cluster2 \
  --project $DEVSHELL_PROJECT_ID \
  --zone=$ZONE \
  --machine-type "e2-standard-4" \
  --num-nodes "2" --min-nodes "2" --max-nodes "2" \
  --enable-ip-alias --enable-autoscaling \
  --workload-pool=$DEVSHELL_PROJECT_ID.svc.id.goog \
  --enable-private-nodes \
  --master-ipv4-cidr=172.16.1.0/28 \
  --enable-master-authorized-networks \
  --master-authorized-networks $NAT_REGION_1_IP_ADDR/32,$CLOUDSHELL_IP/32,$LAB_VM_IP/32

# Step 13: Listing Kubernetes clusters
echo "${GREEN}${BOLD}Listing Kubernetes clusters...${RESET}"
gcloud container clusters list

# Step 14: Setting up Kubernetes credentials
echo "${CYAN}${BOLD}Setting up Kubernetes credentials...${RESET}"
touch ~/asm-kubeconfig && export KUBECONFIG=~/asm-kubeconfig
gcloud container clusters get-credentials cluster1 --zone $ZONE
gcloud container clusters get-credentials cluster2 --zone $ZONE

# Step 15: Renaming Kubernetes contexts
echo "${MAGENTA}${BOLD}Renaming Kubernetes contexts...${RESET}"
kubectl config rename-context gke_${DEVSHELL_PROJECT_ID}_${ZONE}_cluster1 cluster1
kubectl config rename-context gke_${DEVSHELL_PROJECT_ID}_${ZONE}_cluster2 cluster2

# Step 16: Getting Kubernetes contexts
echo "${YELLOW}${BOLD}Getting Kubernetes contexts...${RESET}"
kubectl config get-contexts --output="name"

# Step 17: Registering clusters in Fleet
echo "${BLUE}${BOLD}Registering clusters in Fleet...${RESET}"
gcloud container fleet memberships register cluster1 --gke-cluster=$ZONE/cluster1 --enable-workload-identity
gcloud container fleet memberships register cluster2 --gke-cluster=$ZONE/cluster2 --enable-workload-identity

# Step 18: Updating master authorized networks for clusters
echo "${RED}${BOLD}Updating master authorized networks for clusters...${RESET}"
export CLOUDSHELL_IP=$(dig +short myip.opendns.com @resolver1.opendns.com)
export LAB_VM_IP=$(gcloud compute instances describe lab-setup --format='get(networkInterfaces[0].accessConfigs[0].natIP)' --zone=$ZONE)
export NAT_REGION_1_IP_ADDR=$(gcloud compute addresses describe $REGION-nat-ip \
  --project=$DEVSHELL_PROJECT_ID \
  --region=$REGION \
  --format='value(address)')

gcloud container clusters update cluster1 \
  --zone=$ZONE \
  --enable-master-authorized-networks \
  --master-authorized-networks $NAT_REGION_1_IP_ADDR/32,$CLOUDSHELL_IP/32,$LAB_VM_IP/32

gcloud container clusters update cluster2 \
  --zone=$ZONE \
  --enable-master-authorized-networks \
  --master-authorized-networks $NAT_REGION_1_IP_ADDR/32,$CLOUDSHELL_IP/32,$LAB_VM_IP/32

# Step 19: Enabling automatic fleet mesh management
echo "${GREEN}${BOLD}Enabling automatic fleet mesh management...${RESET}"
gcloud container fleet mesh update --management automatic --memberships cluster1,cluster2

# Function to prompt user to check their progress
function check_progress {
    while true; do
        echo
        echo -n "${BOLD}${YELLOW}Have you checked your progress upto Task 3? (Y/N): ${RESET}"
        read -r user_input
        if [[ "$user_input" == "Y" || "$user_input" == "y" ]]; then
            echo
            echo "${BOLD}${GREEN}Great! Proceeding to the next steps...${RESET}"
            echo
            break
        elif [[ "$user_input" == "N" || "$user_input" == "n" ]]; then
            echo
            echo "${BOLD}${RED}Please check your progress upto Task 3 and then press Y to continue.${RESET}"
        else
            echo
            echo "${BOLD}${MAGENTA}Invalid input. Please enter Y or N.${RESET}"
        fi
    done
}

# Call function to check progress before proceeding
check_progress

# Step 20: Waiting for 'REVISION_READY' status
echo "${CYAN}${BOLD}Waiting for 'REVISION_READY' status...${RESET}"
wait_for_revision_ready() {
    while true; do
        # Run the command and check if 'REVISION_READY' appears at least once
        if gcloud container fleet mesh describe | grep -q "code: REVISION_READY"; then
            echo -e "${GREEN}${BOLD}'REVISION_READY' detected. Proceeding...${RESET}"
            break
        fi
        sleep 30  # Check every 30 seconds
    done
}

wait_for_revision_ready

# Step 21: Setting up ASM ingress namespaces
echo "${MAGENTA}${BOLD}Setting up ASM ingress namespaces...${RESET}"
kubectl --context=cluster1 create namespace asm-ingress
kubectl --context=cluster1 label namespace asm-ingress istio-injection=enabled --overwrite
kubectl --context=cluster2 create namespace asm-ingress
kubectl --context=cluster2 label namespace asm-ingress istio-injection=enabled --overwrite

# Step 22: Deploying ASM ingress gateway
echo "${YELLOW}${BOLD}Deploying ASM ingress gateway...${RESET}"
cat <<'EOF' > asm-ingress.yaml
apiVersion: v1
kind: Service
metadata:
  name: asm-ingressgateway
  namespace: asm-ingress
spec:
  type: LoadBalancer
  selector:
    asm: ingressgateway
  ports:
  - port: 80
    name: http
  - port: 443
    name: https
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: asm-ingressgateway
  namespace: asm-ingress
spec:
  selector:
    matchLabels:
      asm: ingressgateway
  template:
    metadata:
      annotations:
        # This is required to tell GKE Service Mesh to inject the gateway with the
        # required configuration.
        inject.istio.io/templates: gateway
      labels:
        asm: ingressgateway
    spec:
      containers:
      - name: istio-proxy
        image: auto # The image will automatically update each time the pod starts.
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: asm-ingressgateway-sds
  namespace: asm-ingress
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "watch", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: asm-ingressgateway-sds
  namespace: asm-ingress
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: asm-ingressgateway-sds
subjects:
- kind: ServiceAccount
  name: default
EOF

kubectl --context=cluster1 apply -f asm-ingress.yaml
kubectl --context=cluster2 apply -f asm-ingress.yaml

# Step 23: Verifying ASM ingress gateway
echo "${BLUE}${BOLD}Verifying ASM ingress gateway...${RESET}"
kubectl --context=cluster1 get pod,service -n asm-ingress
kubectl --context=cluster2 get pod,service -n asm-ingress

# Step 24: Cloning Bank of Anthos repository
echo "${RED}${BOLD}Cloning Bank of Anthos repository...${RESET}"
git clone https://github.com/GoogleCloudPlatform/bank-of-anthos.git ${HOME}/bank-of-anthos

# Step 25: Setting up Bank of Anthos namespaces
echo "${GREEN}${BOLD}Setting up Bank of Anthos namespaces...${RESET}"
kubectl create --context=cluster1 namespace bank-of-anthos
kubectl label --context=cluster1 namespace bank-of-anthos istio-injection=enabled

kubectl create --context=cluster2 namespace bank-of-anthos
kubectl label --context=cluster2 namespace bank-of-anthos istio-injection=enabled

sleep 30

# Step 26: Applying JWT secret to clusters
echo "${CYAN}${BOLD}Applying JWT secret to clusters...${RESET}"
kubectl --context=cluster1 -n bank-of-anthos apply -f ${HOME}/bank-of-anthos/extras/jwt/jwt-secret.yaml
kubectl --context=cluster2 -n bank-of-anthos apply -f ${HOME}/bank-of-anthos/extras/jwt/jwt-secret.yaml

# Step 27: Deploying Bank of Anthos application
echo "${MAGENTA}${BOLD}Deploying Bank of Anthos application...${RESET}"
kubectl --context=cluster1 -n bank-of-anthos apply -f ${HOME}/bank-of-anthos/kubernetes-manifests
kubectl --context=cluster2 -n bank-of-anthos apply -f ${HOME}/bank-of-anthos/kubernetes-manifests

# Step 28: Removing redundant statefulsets from cluster2
echo "${YELLOW}${BOLD}Removing redundant statefulsets from cluster2...${RESET}"
kubectl --context=cluster2 -n bank-of-anthos delete statefulset accounts-db
kubectl --context=cluster2 -n bank-of-anthos delete statefulset ledger-db

# Step 29: Checking pod status in clusters
echo "${BLUE}${BOLD}Checking pod status in clusters...${RESET}"
kubectl --context=cluster1 -n bank-of-anthos get pod
kubectl --context=cluster2 -n bank-of-anthos get pod

# Step 30: Configuring ASM VirtualService and Gateway
echo "${RED}${BOLD}Configuring ASM VirtualService and Gateway...${RESET}"
cat <<'EOF' > asm-vs-gateway.yaml
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: asm-ingressgateway
  namespace: asm-ingress
spec:
  selector:
    asm: ingressgateway
  servers:
    - port:
        number: 80
        name: http
        protocol: HTTP
      hosts:
        - "*"
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: frontend
  namespace: bank-of-anthos
spec:
  hosts:
  - "*"
  gateways:
  - asm-ingress/asm-ingressgateway
  http:
  - route:
    - destination:
        host: frontend
        port:
          number: 80
EOF

kubectl --context=cluster1 apply -f asm-vs-gateway.yaml
kubectl --context=cluster2 apply -f asm-vs-gateway.yaml

# Step 31: Verifying ASM ingress gateway load balancer
echo "${GREEN}${BOLD}Verifying ASM ingress gateway load balancer...${RESET}"
kubectl --context cluster1 \
--namespace asm-ingress get svc asm-ingressgateway -o jsonpath='{.status.loadBalancer}' | grep "ingress"

kubectl --context cluster2 \
--namespace asm-ingress get svc asm-ingressgateway -o jsonpath='{.status.loadBalancer}' | grep "ingress"

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