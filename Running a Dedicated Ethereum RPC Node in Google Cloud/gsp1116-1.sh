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

export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")

export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")

gcloud compute addresses create eth-mainnet-rpc-ip \
  --region=$REGION

ETH_MAINNET_RPC_IP=$(gcloud compute addresses describe eth-mainnet-rpc-ip --region=$REGION --format='get(address)')

gcloud compute firewall-rules create eth-rpc-node-fw \
  --direction=INGRESS \
  --priority=1000 \
  --network=default \
  --action=ALLOW \
  --rules=tcp:30303,tcp:9000,tcp:8545,udp:30303,udp:9000 \
  --source-ranges=0.0.0.0/0 \
  --target-tags=eth-rpc-node

gcloud iam service-accounts create eth-rpc-node-sa \
  --display-name "eth-rpc-node-sa"

gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
    --member="serviceAccount:eth-rpc-node-sa@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/compute.osLogin"

gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
    --member="serviceAccount:eth-rpc-node-sa@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/servicemanagement.serviceController"

gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
    --member="serviceAccount:eth-rpc-node-sa@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/logging.logWriter"

gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
    --member="serviceAccount:eth-rpc-node-sa@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/monitoring.metricWriter"

gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
    --member="serviceAccount:eth-rpc-node-sa@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/cloudtrace.agent"

gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
    --member="serviceAccount:eth-rpc-node-sa@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/compute.networkUser"

gcloud compute resource-policies create snapshot-schedule eth-mainnet-rpc-node-disk-snapshot \
    --region=$REGION \
    --max-retention-days=7 \
    --on-source-disk-delete=keep-auto-snapshots \
    --daily-schedule \
    --start-time=18:00 \
    --storage-location=$REGION

gcloud compute instances create eth-mainnet-rpc-node \
    --zone=$ZONE \
    --machine-type=e2-medium \
    --network-interface=address=$ETH_MAINNET_RPC_IP,network-tier=PREMIUM,nic-type=GVNIC,stack-type=IPV4_ONLY,subnet=default \
    --metadata=enable-oslogin=true \
    --maintenance-policy=MIGRATE \
    --provisioning-model=STANDARD \
    --service-account=eth-rpc-node-sa@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com \
    --scopes=https://www.googleapis.com/auth/cloud-platform \
    --tags=eth-rpc-node \
    --create-disk=auto-delete=yes,boot=yes,device-name=eth-mainnet-rpc-node,disk-resource-policy=projects/$DEVSHELL_PROJECT_ID/regions/$REGION/resourcePolicies/eth-mainnet-rpc-node-disk-snapshot,image=projects/ubuntu-os-cloud/global/images/ubuntu-2004-focal-v20241115,mode=rw,size=50,type=pd-ssd \
    --create-disk=device-name=eth-mainnet-rpc-node-disk,disk-resource-policy=projects/$DEVSHELL_PROJECT_ID/regions/$REGION/resourcePolicies/eth-mainnet-rpc-node-disk-snapshot,mode=rw,name=eth-mainnet-rpc-node-disk,size=200,type=pd-ssd \
    --no-shielded-secure-boot \
    --shielded-vtpm \
    --shielded-integrity-monitoring \
    --labels=goog-ec-src=vm_add-gcloud \
    --reservation-affinity=any

sleep 30

cat > prepare_disk.sh <<'EOF_END'
sudo dd if=/dev/zero of=/swapfile bs=1MiB count=25KiB
sudo chmod 0600 /swapfile
sudo mkswap /swapfile
echo "/swapfile swap swap defaults 0 0" | sudo tee -a /etc/fstab
sudo swapon -a
free -g
sudo lsblk
sudo mkfs.ext4 -m 0 -E lazy_itable_init=0,lazy_journal_init=0,discard /dev/sdb
sudo mkdir -p /mnt/disks/chaindata-disk
sudo mount -o discard,defaults /dev/sdb /mnt/disks/chaindata-disk
sudo chmod a+w /mnt/disks/chaindata-disk
sudo blkid /dev/sdb
export DISK_UUID=$(findmnt -n -o UUID /dev/sdb)
echo "UUID=$DISK_UUID /mnt/disks/chaindata-disk ext4 discard,defaults,nofail 0 2" | sudo tee -a /etc/fstab
df -h

sudo useradd -m ethereum
sudo usermod -aG sudo ethereum
sudo usermod -aG google-sudoers ethereum
EOF_END

gcloud compute scp prepare_disk.sh eth-mainnet-rpc-node:/tmp --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet

gcloud compute ssh eth-mainnet-rpc-node --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet --command="bash /tmp/prepare_disk.sh"

gcloud compute ssh eth-mainnet-rpc-node --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet