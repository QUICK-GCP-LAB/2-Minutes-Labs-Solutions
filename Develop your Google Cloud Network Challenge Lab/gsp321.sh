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

export REGION="${ZONE%-*}"

gcloud compute networks create griffin-dev-vpc --subnet-mode custom

gcloud compute networks subnets create griffin-dev-wp --network=griffin-dev-vpc --region $REGION --range=192.168.16.0/20

gcloud compute networks subnets create griffin-dev-mgmt --network=griffin-dev-vpc --region $REGION --range=192.168.32.0/20

echo "${RED}${BOLD}Task 1. ${RESET}""${WHITE}${BOLD}Create development VPC manually${RESET}" "${GREEN}${BOLD}Completed${RESET}"

gsutil cp -r gs://cloud-training/gsp321/dm .

cd dm

sed -i s/SET_REGION/$REGION/g prod-network.yaml

gcloud deployment-manager deployments create prod-network \
    --config=prod-network.yaml

cd ..

echo "${RED}${BOLD}Task 2. ${RESET}""${WHITE}${BOLD}Create production VPC manually${RESET}" "${GREEN}${BOLD}Completed${RESET}"

gcloud compute instances create bastion --network-interface=network=griffin-dev-vpc,subnet=griffin-dev-mgmt  --network-interface=network=griffin-prod-vpc,subnet=griffin-prod-mgmt --tags=ssh --zone=$ZONE

gcloud compute firewall-rules create fw-ssh-dev --source-ranges=0.0.0.0/0 --target-tags ssh --allow=tcp:22 --network=griffin-dev-vpc

gcloud compute firewall-rules create fw-ssh-prod --source-ranges=0.0.0.0/0 --target-tags ssh --allow=tcp:22 --network=griffin-prod-vpc


echo "${RED}${BOLD}Task 3. ${RESET}""${WHITE}${BOLD}Create bastion host${RESET}" "${GREEN}${BOLD}Completed${RESET}"

gcloud sql instances create griffin-dev-db \
    --database-version=MYSQL_5_7 \
    --region=$REGION \
    --root-password='awesome'

gcloud sql databases create wordpress --instance=griffin-dev-db
gcloud sql users create wp_user --instance=griffin-dev-db --password=stormwind_rules --instance=griffin-dev-db
gcloud sql users set-password wp_user --instance=griffin-dev-db --password=stormwind_rules --instance=griffin-dev-db
gcloud sql users list --instance=griffin-dev-db --format="value(name)" --filter="host='%'" --instance=griffin-dev-db

echo "${RED}${BOLD}Task 4. ${RESET}""${WHITE}${BOLD}Create and configure Cloud SQL Instance${RESET}" "${GREEN}${BOLD}Completed${RESET}"

gcloud container clusters create griffin-dev \
  --network griffin-dev-vpc \
  --subnetwork griffin-dev-wp \
  --machine-type e2-standard-4 \
  --num-nodes 2  \
  --zone $ZONE

gcloud container clusters get-credentials griffin-dev --zone $ZONE

cd ~/

gsutil cp -r gs://cloud-training/gsp321/wp-k8s .


echo "${RED}${BOLD}Task 5. ${RESET}""${WHITE}${BOLD}Create Kubernetes cluster${RESET}" "${GREEN}${BOLD}Completed${RESET}"

cat > wp-k8s/wp-env.yaml <<EOF_END
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: wordpress-volumeclaim
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 200Gi
---
apiVersion: v1
kind: Secret
metadata:
  name: database
type: Opaque
stringData:
  username: wp_user
  password: stormwind_rules

EOF_END

cd wp-k8s

kubectl create -f wp-env.yaml

gcloud iam service-accounts keys create key.json \
    --iam-account=cloud-sql-proxy@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com
kubectl create secret generic cloudsql-instance-credentials \
    --from-file key.json


echo "${RED}${BOLD}Task 6. ${RESET}""${WHITE}${BOLD}Prepare the Kubernetes cluster${RESET}" "${GREEN}${BOLD}Completed${RESET}"

INSTANCE_ID=$(gcloud sql instances describe griffin-dev-db --format='value(connectionName)')

cat > wp-deployment.yaml <<EOF_END
apiVersion: apps/v1
kind: Deployment
metadata:
  name: wordpress
  labels:
    app: wordpress
spec:
  replicas: 1
  selector:
    matchLabels:
      app: wordpress
  template:
    metadata:
      labels:
        app: wordpress
    spec:
      containers:
        - image: wordpress
          name: wordpress
          env:
          - name: WORDPRESS_DB_HOST
            value: 127.0.0.1:3306
          - name: WORDPRESS_DB_USER
            valueFrom:
              secretKeyRef:
                name: database
                key: username
          - name: WORDPRESS_DB_PASSWORD
            valueFrom:
              secretKeyRef:
                name: database
                key: password
          ports:
            - containerPort: 80
              name: wordpress
          volumeMounts:
            - name: wordpress-persistent-storage
              mountPath: /var/www/html
        - name: cloudsql-proxy
          image: gcr.io/cloudsql-docker/gce-proxy:1.33.2
          command: ["/cloud_sql_proxy",
                    "-instances=$INSTANCE_ID=tcp:3306",
                    "-credential_file=/secrets/cloudsql/key.json"]
          securityContext:
            runAsUser: 2  # non-root user
            allowPrivilegeEscalation: false
          volumeMounts:
            - name: cloudsql-instance-credentials
              mountPath: /secrets/cloudsql
              readOnly: true
      volumes:
        - name: wordpress-persistent-storage
          persistentVolumeClaim:
            claimName: wordpress-volumeclaim
        - name: cloudsql-instance-credentials
          secret:
            secretName: cloudsql-instance-credentials

EOF_END

kubectl create -f wp-deployment.yaml
kubectl create -f wp-service.yaml

echo "${RED}${BOLD}Task 7. ${RESET}""${WHITE}${BOLD}Create a WordPress deployment${RESET}" "${GREEN}${BOLD}Completed${RESET}"

# Get the IAM policy JSON
IAM_POLICY_JSON=$(gcloud projects get-iam-policy $DEVSHELL_PROJECT_ID --format=json)

# Extract user emails with 'roles/viewer' role
USERS=$(echo $IAM_POLICY_JSON | jq -r '.bindings[] | select(.role == "roles/viewer").members[]')

# Grant 'roles/editor' role to extracted users
for USER in $USERS; do
  if [[ $USER == *"user:"* ]]; then
    USER_EMAIL=$(echo $USER | cut -d':' -f2)
    gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
      --member=user:$USER_EMAIL \
      --role=roles/editor
  fi
done

echo "${RED}${BOLD}Task 9. ${RESET}""${WHITE}${BOLD}Provide access for an additional engineer${RESET}" "${GREEN}${BOLD}Completed${RESET}"

echo "${RED}${BOLD}Congratulations${RESET}" "${WHITE}${BOLD}for${RESET}" "${GREEN}${BOLD}Completing the Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#
