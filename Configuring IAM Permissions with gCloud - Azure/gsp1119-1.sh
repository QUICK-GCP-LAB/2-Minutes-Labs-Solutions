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

gcloud config set compute/zone "$ZONE"
export ZONE=$(gcloud config get compute/zone)
gcloud config set compute/region "${ZONE%-*}"
export REGION=$(gcloud config get compute/region)
gcloud compute instances create lab-1 --zone=$ZONE

cat << 'EOF' > toggle_zone_script.sh
#!/bin/bash
last_char="${ZONE: -1}"
if [ "$last_char" == "a" ]; then
    export NZONE="${ZONE%?}b"  
elif [ "$last_char" == "b" ]; then
    export NZONE="${ZONE%?}c" 
elif [ "$last_char" == "c" ]; then
    export NZONE="${ZONE%?}b"
elif [ "$last_char" == "d" ]; then
    export NZONE="${ZONE%?}b"
fi
echo "$NZONE"
EOF

chmod +x toggle_zone_script.sh
NEWZONE=$(./toggle_zone_script.sh)
gcloud config set compute/zone $NEWZONE
gcloud init --no-launch-browser