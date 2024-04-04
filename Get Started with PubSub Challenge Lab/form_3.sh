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

gcloud pubsub snapshots create pubsub-snapshot --subscription=gcloud-pubsub-subscription

gcloud pubsub lite-reservations create pubsub-lite-reservation \
  --location=$LOCATION \
  --throughput-capacity=1

gcloud pubsub lite-topics create cloud-pubsub-topic-lite \
  --location=$LOCATION \
  --partitions=1 \
  --per-partition-bytes=30GiB \
  --throughput-reservation=demo-reservation

gcloud pubsub lite-subscriptions create cloud-pubsub-subscription-lite \
  --location=$LOCATION \
  --topic=cloud-pubsub-topic-lite

echo "${RED}${BOLD}Congratulations${RESET}" "${WHITE}${BOLD}for${RESET}" "${GREEN}${BOLD}Completing the Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#