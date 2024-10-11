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

export PROJECT_ID=$(gcloud config get-value project)
export service_account="baremetal-gcr"
export cluster_name=anthos-bm-cluster-1

gcloud iam service-accounts create baremetal-gcr
gcloud iam service-accounts keys create bm-gcr.json \
--iam-account=baremetal-gcr@${PROJECT_ID}.iam.gserviceaccount.com

gcloud services enable \
    anthos.googleapis.com \
    anthosaudit.googleapis.com \
    anthosgke.googleapis.com \
    cloudresourcemanager.googleapis.com \
    container.googleapis.com \
    gkeconnect.googleapis.com \
    gkehub.googleapis.com \
    serviceusage.googleapis.com \
    stackdriver.googleapis.com \
    monitoring.googleapis.com \
    logging.googleapis.com \
    connectgateway.googleapis.com \
    opsconfigmonitoring.googleapis.com


gcloud projects add-iam-policy-binding $PROJECT_ID \
--member="serviceAccount:baremetal-gcr@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/gkehub.connect"

gcloud projects add-iam-policy-binding $PROJECT_ID \
--member="serviceAccount:baremetal-gcr@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/gkehub.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
--member="serviceAccount:baremetal-gcr@$PROJECT_ID.iam.gserviceaccount.com" \
--role="roles/logging.logWriter"

gcloud projects add-iam-policy-binding $PROJECT_ID \
--member="serviceAccount:baremetal-gcr@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/monitoring.metricWriter"

gcloud projects add-iam-policy-binding $PROJECT_ID \
--member="serviceAccount:baremetal-gcr@$PROJECT_ID.iam.gserviceaccount.com" \
--role="roles/monitoring.dashboardEditor"

gcloud projects add-iam-policy-binding $PROJECT_ID \
--member="serviceAccount:baremetal-gcr@$PROJECT_ID.iam.gserviceaccount.com" \
--role="roles/stackdriver.resourceMetadata.writer"

gcloud projects add-iam-policy-binding $PROJECT_ID \
--member="serviceAccount:baremetal-gcr@$PROJECT_ID.iam.gserviceaccount.com" \
--role="roles/opsconfigmonitoring.resourceMetadata.writer"

sleep 30

VM_PREFIX=abm
VM_WS=$VM_PREFIX-ws
VM_CP1=$VM_PREFIX-cp1
VM_W1=$VM_PREFIX-w1
VM_W2=$VM_PREFIX-w2
declare -a CP_W_VMs=("$VM_CP1" "$VM_W1" "$VM_W2")
declare -a VMs=("$VM_WS" "$VM_CP1" "$VM_W1" "$VM_W2")
declare -a IPs=()

gcloud compute instances create $VM_WS \
          --image-family=ubuntu-2204-lts \
          --image-project=ubuntu-os-cloud \
          --zone=${ZONE} \
          --boot-disk-size 50G \
          --boot-disk-type pd-ssd \
          --can-ip-forward \
          --network default \
          --tags http-server,https-server \
          --scopes cloud-platform \
          --custom-cpu=6 \
          --custom-memory=16GB \
          --custom-vm-type=e2 \
          --metadata=enable-oslogin=FALSE
IP=$(gcloud compute instances describe $VM_WS --zone ${ZONE} \
     --format='get(networkInterfaces[0].networkIP)')
IPs+=("$IP")

for vm in "${CP_W_VMs[@]}"
do
    gcloud compute instances create $vm \
              --image-family=ubuntu-2204-lts \
              --image-project=ubuntu-os-cloud \
              --zone=${ZONE} \
              --boot-disk-size 150G \
              --boot-disk-type pd-ssd \
              --can-ip-forward \
              --network default \
              --tags http-server,https-server \
              --scopes cloud-platform \
              --custom-cpu=6 \
              --custom-memory=16GB \
              --custom-vm-type=e2 \
              --metadata=enable-oslogin=FALSE
    IP=$(gcloud compute instances describe $vm --zone ${ZONE} \
         --format='get(networkInterfaces[0].networkIP)')
    IPs+=("$IP")
done

for vm in "${VMs[@]}"
do
    while ! gcloud compute ssh root@$vm --zone=$ZONE --command "echo SSH to $vm succeeded" </dev/null
    do
        echo "Trying to SSH into $vm failed. Sleeping for 5 seconds. zzzZZzzZZ"
        sleep 5
    done
done

i=2
for vm in "${VMs[@]}"
do
    gcloud compute ssh root@$vm --zone ${ZONE} << EOF
        apt-get -qq update > /dev/null
        apt-get -qq install -y jq > /dev/null
        set -x
        ip link add vxlan0 type vxlan id 42 dev ens4 dstport 0
        current_ip=\$(ip --json a show dev ens4 | jq '.[0].addr_info[0].local' -r)
        echo "VM IP address is: \$current_ip"
        for ip in ${IPs[@]}; do
            if [ "\$ip" != "\$current_ip" ]; then
                bridge fdb append to 00:00:00:00:00:00 dst \$ip dev vxlan0
            fi
        done
        ip addr add 10.200.0.$i/24 dev vxlan0
        ip link set up dev vxlan0
        systemctl stop apparmor.service
        systemctl disable apparmor.service
EOF
    i=$((i+1))
done

gcloud compute ssh root@$VM_WS --zone ${ZONE} << EOF
set -x
export PROJECT_ID=\$(gcloud config get-value project)
gcloud iam service-accounts keys create bm-gcr.json \
--iam-account=baremetal-gcr@\${PROJECT_ID}.iam.gserviceaccount.com
curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/sbin/
mkdir baremetal && cd baremetal
gsutil cp gs://anthos-baremetal-release/bmctl/1.16.2/linux-amd64/bmctl .
chmod a+x bmctl
mv bmctl /usr/local/sbin/
cd ~
echo "Installing docker"
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
# Install siege
cd ~
apt install siege -y
siege -V
cat /root/.siege/siege.conf \
| sed -e "s:^\(connection \=\).*:connection \= keep-alive:" \
> /root/.siege/siege.conf.new
mv /root/.siege/siege.conf.new /root/.siege/siege.conf
EOF

gcloud compute ssh root@$VM_WS --zone ${ZONE} << EOF
set -x
ssh-keygen -t rsa -N "" -f /root/.ssh/id_rsa
sed 's/ssh-rsa/root:ssh-rsa/' ~/.ssh/id_rsa.pub > ssh-metadata
for vm in ${VMs[@]}
do
    gcloud compute instances add-metadata \$vm --zone ${ZONE} --metadata-from-file ssh-keys=ssh-metadata
done
EOF

echo "${BG_RED}${BOLD}Congratulations For Completing The Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#