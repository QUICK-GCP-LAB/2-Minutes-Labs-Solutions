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

gcloud bigtable instances create sandiego \
--display-name="San Diego Traffic Sensors" \
--cluster-storage-type=SSD \
--cluster-config=id=sandiego-traffic-sensors-c1,zone=$ZONE,nodes=1

echo project = `gcloud config get-value project` \
    >> ~/.cbtrc

echo instance = sandiego \
    >> ~/.cbtrc

cat ~/.cbtrc

cbt createtable current_conditions \
    families="lane"

cat > prepare_disk.sh <<'EOF_END'

ls /training

git clone https://github.com/GoogleCloudPlatform/training-data-analyst

source /training/project_env.sh

/training/sensor_magic.sh

EOF_END

export ZONE=$(gcloud compute instances list training-vm --format 'csv[no-heading](zone)')

gcloud compute scp prepare_disk.sh training-vm:/tmp --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet

gcloud compute ssh training-vm --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet --command="bash /tmp/prepare_disk.sh"

#-----------------------------------------------------end----------------------------------------------------------#