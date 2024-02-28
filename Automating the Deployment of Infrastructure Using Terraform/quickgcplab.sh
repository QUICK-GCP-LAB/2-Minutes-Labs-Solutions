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

gcloud auth list

mkdir tfinfra

cd tfinfra

wget https://raw.githubusercontent.com/QUICK-GCP-LAB/2-Minutes-Labs-Solutions/main/Automating%20the%20Deployment%20of%20Infrastructure%20Using%20Terraform/provider.tf

wget https://raw.githubusercontent.com/QUICK-GCP-LAB/2-Minutes-Labs-Solutions/main/Automating%20the%20Deployment%20of%20Infrastructure%20Using%20Terraform/terraform.tfstate

wget https://raw.githubusercontent.com/QUICK-GCP-LAB/2-Minutes-Labs-Solutions/main/Automating%20the%20Deployment%20of%20Infrastructure%20Using%20Terraform/variables.tf

wget https://raw.githubusercontent.com/QUICK-GCP-LAB/2-Minutes-Labs-Solutions/main/Automating%20the%20Deployment%20of%20Infrastructure%20Using%20Terraform/mynetwork.tf

mkdir instance

cd instance

wget https://raw.githubusercontent.com/QUICK-GCP-LAB/2-Minutes-Labs-Solutions/main/Automating%20the%20Deployment%20of%20Infrastructure%20Using%20Terraform/main.tf

cd ..

terraform init

terraform fmt

terraform init

echo -e "mynet-us-vm\nmynetwork\n$ZONE" | terraform plan -var="instance_name=$(</dev/stdin)" -var="instance_network=$(</dev/stdin)" -var="instance_zone=$(</dev/stdin)"

echo -e "mynet-us-vm\nmynetwork\n$ZONE" | terraform apply -var="instance_name=$(</dev/stdin)" -var="instance_network=$(</dev/stdin)" -var="instance_zone=$(</dev/stdin)" --auto-approve

echo "${RED}${BOLD}Congratulations${RESET}" "${WHITE}${BOLD}for${RESET}" "${GREEN}${BOLD}Completing the Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#