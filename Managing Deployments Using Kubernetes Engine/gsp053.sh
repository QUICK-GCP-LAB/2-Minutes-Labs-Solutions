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

cat > main.tf <<EOF_END

provider "google" {
  project     = "$DEVSHELL_PROJECT_ID"
  region      = "$REGION"
}
resource "google_storage_bucket" "test-bucket-for-state" {
  name        = "$DEVSHELL_PROJECT_ID"
  location    = "US"
  uniform_bucket_level_access = true
}

terraform {
  backend "local" {
    path = "terraform/state/terraform.tfstate"
  }
}
EOF_END

terraform init

terraform apply --auto-approve

cat > main.tf <<EOF_END

provider "google" {
  project     = "$DEVSHELL_PROJECT_ID"
  region      = "$REGION"
}
resource "google_storage_bucket" "test-bucket-for-state" {
  name        = "$DEVSHELL_PROJECT_ID"
  location    = "US"
  uniform_bucket_level_access = true
}

terraform {
  backend "gcs" {
    bucket  = "$DEVSHELL_PROJECT_ID"
    prefix  = "terraform/state"
  }
}
EOF_END

yes | terraform init -migrate-state

gsutil label ch -l "key:value" gs://$DEVSHELL_PROJECT_ID

echo "${RED}${BOLD}Congratulations${RESET}" "${WHITE}${BOLD}for${RESET}" "${GREEN}${BOLD}Completing the Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#