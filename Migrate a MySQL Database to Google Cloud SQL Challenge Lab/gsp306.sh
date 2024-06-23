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

REGION="${ZONE%-*}"

gcloud sql instances create wordpress --tier=db-n1-standard-1 --activation-policy=ALWAYS --zone $ZONE

gcloud sql users set-password --host % root --instance wordpress --password Password1*

ADDRESS=$(gcloud compute instances describe blog --zone=$ZONE --format="get(networkInterfaces[0].accessConfigs[0].natIP)")/32

gcloud sql instances patch wordpress --authorized-networks $ADDRESS --quiet

cat > prepare_disk.sh <<'EOF_END'

sudo apt-get update
sudo apt-get install -y mysql-client

gcloud auth login --no-launch-browser --quiet

echo 'Password1*' | mysql_config_editor set --login-path=local --host=$MYSQLIP --user=root --password

MYSQLIP=$(gcloud sql instances describe wordpress --format="value(ipAddresses.ipAddress)")

export MYSQL_PWD=Password1*

mysql --host=$MYSQLIP --user=root << EOF
CREATE DATABASE wordpress;
CREATE USER 'blogadmin'@'%' IDENTIFIED BY 'Password1*';
GRANT ALL PRIVILEGES ON wordpress.* TO 'blogadmin'@'%';
FLUSH PRIVILEGES;
EOF

sudo mysqldump -u root -pPassword1* wordpress > wordpress_backup.sql

mysql --host=$MYSQLIP --user=root -pPassword1* --verbose wordpress < wordpress_backup.sql

sudo service apache2 restart

cd /var/www/html/wordpress

EXTERNAL_IP=$(gcloud sql instances describe wordpress --format="value(ipAddresses[0].ipAddress)")

CONFIG_FILE="wp-config.php"

sudo sed -i "s/define('DB_HOST', 'localhost')/define('DB_HOST', '$EXTERNAL_IP')/" $CONFIG_FILE

EOF_END

gcloud compute scp prepare_disk.sh blog:/tmp --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet

gcloud compute ssh blog --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet --command="bash /tmp/prepare_disk.sh"

echo "${BG_RED}${BOLD}Congratulations For Completing The Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#