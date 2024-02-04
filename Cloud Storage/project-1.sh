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

echo "${YELLOW}${BOLD}

Starting Execution 

${RESET}"

export REGION="${ZONE%-*}"

gsutil mb -p $DEVSHELL_PROJECT_ID -c STANDARD -l $REGION -b on gs://$DEVSHELL_PROJECT_ID

gsutil uniformbucketlevelaccess set off gs://$DEVSHELL_PROJECT_ID


export BUCKET_NAME_1=$DEVSHELL_PROJECT_ID

curl \
https://hadoop.apache.org/docs/current/\
hadoop-project-dist/hadoop-common/\
ClusterSetup.html > setup.html

cp setup.html setup2.html
cp setup.html setup3.html

echo "${GREEN}${BOLD}

Task 1. Preparation Completed

${RESET}"

gcloud storage cp setup.html gs://$BUCKET_NAME_1/

gsutil acl get gs://$BUCKET_NAME_1/setup.html  > acl.txt
cat acl.txt


gsutil acl set private gs://$BUCKET_NAME_1/setup.html
gsutil acl get gs://$BUCKET_NAME_1/setup.html  > acl2.txt
cat acl2.txt


gsutil acl ch -u AllUsers:R gs://$BUCKET_NAME_1/setup.html
gsutil acl get gs://$BUCKET_NAME_1/setup.html  > acl3.txt
cat acl3.txt

rm setup.html

gcloud storage cp gs://$BUCKET_NAME_1/setup.html setup.html

echo "${GREEN}${BOLD}

Task 2. Access control lists (ACLs) Completed

${RESET}"

# Store the generated key in a variable
CSEK_KEY=$(python3 -c 'import base64; import os; print(base64.encodebytes(os.urandom(32)).decode("utf-8").strip())')

# Print the value to verify
echo "Generated CSEK Key: $CSEK_KEY"

gsutil config -n

sed -i "324c\encryption_key=$CSEK_KEY" .boto

gsutil cp setup2.html gs://$BUCKET_NAME_1/
gsutil cp setup3.html gs://$BUCKET_NAME_1/

rm setup*

gsutil cp gs://$BUCKET_NAME_1/setup* ./

cat setup.html
cat setup2.html
cat setup3.html

echo "${GREEN}${BOLD}

Task 3. Customer-supplied encryption keys (CSEK) Completed

${RESET}"

sed -i "324c\#encryption_key=$CSEK_KEY" .boto

sed -i "331c\decryption_key1=$CSEK_KEY" .boto


# Store the generated key in a variable
CSEK_KEY=$(python3 -c 'import base64; import os; print(base64.encodebytes(os.urandom(32)).decode("utf-8").strip())')

# Print the value to verify
echo "Generated CSEK Key: $CSEK_KEY"

sed -i "324c\encryption_key=$CSEK_KEY" .boto

gsutil rewrite -k gs://$BUCKET_NAME_1/setup2.html

sed -i "331c\#decryption_key1=$CSEK_KEY" .boto


gsutil cp gs://$BUCKET_NAME_1/setup2.html recover2.html

gsutil cp gs://$BUCKET_NAME_1/setup3.html recover3.html

echo "${GREEN}${BOLD}

Task 4. Rotate CSEK keys Completed

${RESET}"

gsutil lifecycle get gs://$BUCKET_NAME_1


cat > life.json <<'EOF_END'
{
  "rule":
  [
    {
      "action": {"type": "Delete"},
      "condition": {"age": 31}
    }
  ]
}
EOF_END

gsutil lifecycle set life.json gs://$BUCKET_NAME_1

gsutil lifecycle get gs://$BUCKET_NAME_1

echo "${GREEN}${BOLD}

Task 5. Enable lifecycle management Completed

${RESET}"

gsutil versioning get gs://$BUCKET_NAME_1

gsutil versioning set on gs://$BUCKET_NAME_1

gsutil versioning get gs://$BUCKET_NAME_1

ls -al setup.html

sed -i '5,9d' setup.html

gcloud storage cp -v setup.html gs://$BUCKET_NAME_1

sed -i '5,9d' setup.html

gcloud storage cp -v setup.html gs://$BUCKET_NAME_1

gcloud storage ls -a gs://$BUCKET_NAME_1/setup.html

VARIABLE=$(gcloud storage ls -a gs://$BUCKET_NAME_1/setup.html | head -n 1 | awk '{print $1}')

export VERSION_NAME=$VARIABLE

gcloud storage cp $VERSION_NAME recovered.txt

echo "${GREEN}${BOLD}

Task 6. Enable versioning Completed

${RESET}"

mkdir firstlevel
mkdir ./firstlevel/secondlevel
cp setup.html firstlevel
cp setup.html firstlevel/secondlevel

gsutil rsync -r ./firstlevel gs://$BUCKET_NAME_1/firstlevel


sleep 30

gcloud compute instances create crossproject --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --machine-type=e2-medium --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=default --metadata=enable-oslogin=true --maintenance-policy=MIGRATE --provisioning-model=STANDARD --scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/trace.append --create-disk=auto-delete=yes,boot=yes,device-name=crossproject,image=projects/debian-cloud/global/images/debian-11-bullseye-v20240110,mode=rw,size=10,type=projects/$DEVSHELL_PROJECT_ID/zones/$ZONE/diskTypes/pd-balanced --no-shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring --labels=goog-ec-src=vm_add-gcloud --reservation-affinity=any

echo "${GREEN}${BOLD}

Task 7. Synchronize a directory to a bucket Completed

${RESET}"

echo "${WHITE}${BOLD}

Now Switch to the Second Project

${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#