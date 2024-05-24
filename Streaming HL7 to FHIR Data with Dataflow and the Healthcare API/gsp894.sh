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

echo "${YELLOW}${BOLD}Starting${RESET}" "${GREEN}${BOLD}Execution${RESET}"

export REGION="${ZONE%-*}"

gcloud config set compute/zone $ZONE

gcloud config set compute/region $REGION

gcloud services enable compute.googleapis.com container.googleapis.com dataflow.googleapis.com bigquery.googleapis.com pubsub.googleapis.com healthcare.googleapis.com

export PROJECT_ID=$(gcloud config list --format 'value(core.project)')
export PROJECT_NUMBER=$(gcloud projects list --filter=${PROJECT_ID} --format='value(PROJECT_NUMBER)')
export COMPUTE_SA=${PROJECT_NUMBER}-compute
export LOCATION=$(gcloud config get-value compute/region)
export DATASET_ID=datastore
export FHIR_STORE_ID=fhirstore
export FHIR_TOPIC=fhirtopic
export HL7_TOPIC=hl7topic
export HL7_SUB=hl7subscription
export HL7_STORE_ID=hl7v2store
export BQ_FHIR=fhirdata
export PSSAN=pubsub-svc
export FILENAME=svca-key
export DEFAULT_ZONE=$(gcloud config get-value compute/zone)
export ERROR_BUCKET=${PROJECT_ID}-df-pipeline/error/
export MAPPING_BUCKET=${PROJECT_ID}-df-pipeline/mapping

gcloud pubsub topics create ${HL7_TOPIC}
gcloud pubsub subscriptions create ${HL7_SUB} --topic=${HL7_TOPIC}
gcloud pubsub topics create ${FHIR_TOPIC}

bq mk --dataset --location=${LOCATION} --project_id=${PROJECT_ID} --description HCAPI-FHIR-dataset ${PROJECT_ID}:${BQ_FHIR}

gcloud healthcare datasets create ${DATASET_ID} --location=${LOCATION}
gcloud healthcare hl7v2-stores create ${HL7_STORE_ID} \
--dataset=${DATASET_ID} \
--location=${LOCATION} \
--notification-config=pubsub-topic=projects/${PROJECT_ID}/topics/${HL7_TOPIC}
gcloud healthcare fhir-stores create ${FHIR_STORE_ID} \
--dataset=${DATASET_ID} \
--location=${LOCATION} \
--version=R4 \
--pubsub-topic=projects/${PROJECT_ID}/topics/${FHIR_TOPIC} \
--disable-referential-integrity \
--enable-update-create

sleep 100

gcloud iam service-accounts create ${PSSAN}
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
--member=serviceAccount:${PSSAN}@${PROJECT_ID}.iam.gserviceaccount.com \
--role=roles/pubsub.subscriber
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
--member=serviceAccount:${PSSAN}@${PROJECT_ID}.iam.gserviceaccount.com \
--role=roles/healthcare.hl7V2Ingest
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
--member=serviceAccount:${PSSAN}@${PROJECT_ID}.iam.gserviceaccount.com \
--role=roles/monitoring.metricWriter
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
--member=serviceAccount:service-${PROJECT_NUMBER}@gcp-sa-healthcare.iam.gserviceaccount.com \
--role=roles/bigquery.dataEditor
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
--member=serviceAccount:service-${PROJECT_NUMBER}@gcp-sa-healthcare.iam.gserviceaccount.com \
--role=roles/bigquery.jobUser
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
--member=serviceAccount:service-${PROJECT_NUMBER}@gcp-sa-healthcare.iam.gserviceaccount.com \
--role=roles/storage.objectAdmin
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
--member=serviceAccount:service-${PROJECT_NUMBER}@gcp-sa-healthcare.iam.gserviceaccount.com \
--role=roles/healthcare.datasetAdmin
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
--member=serviceAccount:service-${PROJECT_NUMBER}@gcp-sa-healthcare.iam.gserviceaccount.com \
--role=roles/healthcare.dicomStoreAdmin
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
--member=serviceAccount:${COMPUTE_SA}@developer.gserviceaccount.com \
--role=roles/pubsub.subscriber
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
--member=serviceAccount:${COMPUTE_SA}@developer.gserviceaccount.com \
--role=roles/editor
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
--member=serviceAccount:${COMPUTE_SA}@developer.gserviceaccount.com \
--role=roles/healthcare.hl7V2Consumer
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
--member=serviceAccount:${COMPUTE_SA}@developer.gserviceaccount.com \
--role=roles/healthcare.fhirResourceEditor

gsutil mb gs://${PROJECT_ID}-df-pipeline
git clone https://github.com/GoogleCloudPlatform/healthcare-data-harmonization
sed -i 's|\$MAPPING_ENGINE_HOME|gs://'"${MAPPING_BUCKET}"'|g' healthcare-data-harmonization/wstl1/mapping_configs/hl7v2_fhir_r4/configurations/main.textproto
sed -i 's|local_path|gcs_location|g' healthcare-data-harmonization/wstl1/mapping_configs/hl7v2_fhir_r4/configurations/main.textproto
gsutil -m cp -r healthcare-data-harmonization/wstl1/mapping_configs gs://${PROJECT_ID}-df-pipeline/mapping/mapping_configs
touch empty.txt
gsutil cp empty.txt gs://${PROJECT_ID}-df-pipeline/error/empty.txt
gsutil cp empty.txt gs://${PROJECT_ID}-df-pipeline/temp/empty.txt

curl -X PATCH \
   -H "Authorization: Bearer $(gcloud auth application-default print-access-token)" \
   -H "Content-Type: application/json; charset=utf-8" \
   --data "{
     'parserConfig': {
       'schema': {
         'schematizedParsingType': 'HARD_FAIL',
         'ignoreMinOccurs' :true,
         'unexpectedSegmentHandling' : 'PARSE'
       }
     }
   }" "https://healthcare.googleapis.com/v1/projects/${PROJECT_ID}/locations/${LOCATION}/datasets/${DATASET_ID}/hl7V2Stores/${HL7_STORE_ID}?updateMask=parser_config.schema"

curl -X PATCH \
  -H "Authorization: Bearer $(gcloud auth application-default print-access-token)" \
  -H "Content-Type: application/json; charset=utf-8" \
  --data "{
 'streamConfigs': [
   { 'bigqueryDestination': {
     'datasetUri': 'bq://${PROJECT_ID}.${BQ_FHIR}', 'schemaConfig': {
       'schemaType': 'ANALYTICS'
       }
     }
   }
 ]
}" "https://healthcare.googleapis.com/v1/projects/${PROJECT_ID}/locations/${LOCATION}/datasets/${DATASET_ID}/fhirStores/${FHIR_STORE_ID}?updateMask=streamConfigs"

gcloud container clusters create "hl7-fhir-gke" \
--project ${PROJECT_ID} \
--zone ${DEFAULT_ZONE} \
--no-enable-basic-auth \
--cluster-version "$(gcloud container get-server-config --flatten="channels" --filter="channels.channel=STABLE" --format="yaml(channels.channel,channels.defaultVersion)" --zone=${DEFAULT_ZONE} --verbosity=none | grep default | awk '{print $2}')" \
--release-channel "stable" \
--machine-type "e2-standard-4" \
--image-type "COS_CONTAINERD" \
--disk-type "pd-standard" \
--disk-size "100" \
--metadata disable-legacy-endpoints=true \
--scopes "https://www.googleapis.com/auth/cloud-platform" \
--max-pods-per-node "110" \
--enable-autoscaling \
--num-nodes "3" \
--min-nodes "2" \
--max-nodes "3" \
--logging=SYSTEM,WORKLOAD \
--monitoring=SYSTEM \
--enable-ip-alias \
--network "projects/${PROJECT_ID}/global/networks/default" \
--subnetwork "projects/${PROJECT_ID}/regions/${LOCATION}/subnetworks/default" \
--no-enable-intra-node-visibility \
--default-max-pods-per-node "110" \
--no-enable-master-authorized-networks \
--addons HorizontalPodAutoscaling,HttpLoadBalancing,GcePersistentDiskCsiDriver \
--enable-autoupgrade --enable-autorepair --max-surge-upgrade 1 --max-unavailable-upgrade 0 --enable-shielded-nodes \
--node-locations ${DEFAULT_ZONE}

gcloud container clusters get-credentials hl7-fhir-gke

cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
 name: mllp-adapter-deployment
spec:
 replicas: 1
 selector:
   matchLabels:
     app: mllp-adapter
 template:
   metadata:
     labels:
       app: mllp-adapter
   spec:
     containers:
       - name: mllp-adapter
         imagePullPolicy: Always
         image: gcr.io/cloud-healthcare-containers/mllp-adapter
         ports:
           - containerPort: 2575
             protocol: TCP
             name: "port"
         command:
           - "/usr/mllp_adapter/mllp_adapter"
           - "--port=2575"
           - "--hl7_v2_project_id=${PROJECT_ID}"
           - "--hl7_v2_location_id=${LOCATION}"
           - "--hl7_v2_dataset_id=${DATASET_ID}"
           - "--hl7_v2_store_id=${HL7_STORE_ID}"
           - "--logtostderr"
           - "--receiver_ip=0.0.0.0"
EOF
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
 name: mllp-adapter-service
 annotations:
   cloud.google.com/load-balancer-type: "Internal"
spec:
 type: LoadBalancer
 ports:
 - name: port
   port: 2575
   targetPort: 2575
   protocol: TCP
 selector:
   app: mllp-adapter
EOF

cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
 name: simhospital-deployment
spec:
 replicas: 1
 selector:
   matchLabels:
     app: simhospital
 template:
   metadata:
     labels:
       app: simhospital
   spec:
     containers:
       - name: simhospital
         imagePullPolicy: Always
         image: us-docker.pkg.dev/qwiklabs-resources/healthcare-qwiklabs-resources/simhospital:latest
         ports:
           - containerPort: 8000
             protocol: TCP
             name: "port"
         command: ["/health/simulator"]
         args: ["-output=mllp", "-mllp_destination=$(kubectl get svc | grep mllp-adapter | awk {print'$4'}):2575"]
EOF

cat <<EOF | kubectl replace --force -f -
apiVersion: v1
kind: Pod
metadata:
 labels:
   run: dataflow-pipeline
 name: dataflow-pipeline
spec:
 containers:
 - command:
   - /usr/local/openjdk-11/bin/java
   - -jar
   - /root/converter-0.1.0-all.jar
   - --pubSubSubscription=projects/${PROJECT_ID}/subscriptions/${HL7_SUB}
   - --readErrorPath=gs://${ERROR_BUCKET}read/read_error.txt
   - --writeErrorPath=gs://${ERROR_BUCKET}write/write_error.txt
   - --mappingErrorPath=gs://${ERROR_BUCKET}mapping/mapping_error.txt
   - --mappingPath=gs://${MAPPING_BUCKET}/mapping_configs/hl7v2_fhir_r4/configurations/main.textproto
   - --fhirStore=projects/${PROJECT_ID}/locations/${LOCATION}/datasets/${DATASET_ID}/fhirStores/${FHIR_STORE_ID}
   - --tempLocation=gs://${PROJECT_ID}-df-pipeline/temp
   - --runner=DataflowRunner
   - --project=${PROJECT_ID}
   - --region=${LOCATION}
   image: us-docker.pkg.dev/qwiklabs-resources/healthcare-qwiklabs-resources/dataflow-pipeline:v0.02
   imagePullPolicy: Always
   name: dataflow-pipeline
 restartPolicy: Never
EOF

gcloud dataflow jobs list --region ${LOCATION}

curl -X GET \
     -H "Authorization: Bearer "$(gcloud auth print-access-token) \
     -H "Content-Type: application/json; charset=utf-8" \
     "https://healthcare.googleapis.com/v1/projects/${PROJECT_ID}/locations/${LOCATION}/datasets/${DATASET_ID}/hl7V2Stores/${HL7_STORE_ID}/messages"

cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
 name: mllp-adapter-deployment
spec:
 replicas: 1
 selector:
   matchLabels:
     app: mllp-adapter
 template:
   metadata:
     labels:
       app: mllp-adapter
   spec:
     containers:
       - name: mllp-adapter
         imagePullPolicy: Always
         image: gcr.io/cloud-healthcare-containers/mllp-adapter
         ports:
           - containerPort: 2575
             protocol: TCP
             name: "port"
         command:
           - "/usr/mllp_adapter/mllp_adapter"
           - "--port=2575"
           - "--hl7_v2_project_id=${PROJECT_ID}"
           - "--hl7_v2_location_id=${LOCATION}"
           - "--hl7_v2_dataset_id=${DATASET_ID}"
           - "--hl7_v2_store_id=${HL7_STORE_ID}"
           - "--logtostderr"
           - "--receiver_ip=0.0.0.0"
EOF
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
 name: mllp-adapter-service
 annotations:
   cloud.google.com/load-balancer-type: "Internal"
spec:
 type: LoadBalancer
 ports:
 - name: port
   port: 2575
   targetPort: 2575
   protocol: TCP
 selector:
   app: mllp-adapter
EOF

sleep 100

cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
 name: simhospital-deployment
spec:
 replicas: 1
 selector:
   matchLabels:
     app: simhospital
 template:
   metadata:
     labels:
       app: simhospital
   spec:
     containers:
       - name: simhospital
         imagePullPolicy: Always
         image: us-docker.pkg.dev/qwiklabs-resources/healthcare-qwiklabs-resources/simhospital:latest
         ports:
           - containerPort: 8000
             protocol: TCP
             name: "port"
         command: ["/health/simulator"]
         args: ["-output=mllp", "-mllp_destination=$(kubectl get svc | grep mllp-adapter | awk {print'$4'}):2575"]
EOF



curl -X GET \
     -H "Authorization: Bearer "$(gcloud auth print-access-token) \
     -H "Content-Type: application/json; charset=utf-8" \
     "https://healthcare.googleapis.com/v1/projects/${PROJECT_ID}/locations/${LOCATION}/datasets/${DATASET_ID}/hl7V2Stores/${HL7_STORE_ID}/messages"

cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
 name: simhospital-deployment
spec:
 replicas: 1
 selector:
   matchLabels:
     app: simhospital
 template:
   metadata:
     labels:
       app: simhospital
   spec:
     containers:
       - name: simhospital
         imagePullPolicy: Always
         image: us-docker.pkg.dev/qwiklabs-resources/healthcare-qwiklabs-resources/simhospital:latest
         ports:
           - containerPort: 8000
             protocol: TCP
             name: "port"
         command: ["/health/simulator"]
         args: ["-output=mllp", "-mllp_destination=$(kubectl get svc | grep mllp-adapter | awk {print'$4'}):2575"]
EOF

curl -X GET \
     -H "Authorization: Bearer "$(gcloud auth print-access-token) \
     -H "Content-Type: application/json; charset=utf-8" \
     "https://healthcare.googleapis.com/v1/projects/${PROJECT_ID}/locations/${LOCATION}/datasets/${DATASET_ID}/hl7V2Stores/${HL7_STORE_ID}/messages"

kubectl get pods

cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
 name: simhospital-deployment
spec:
 replicas: 1
 selector:
   matchLabels:
     app: simhospital
 template:
   metadata:
     labels:
       app: simhospital
   spec:
     containers:
       - name: simhospital
         imagePullPolicy: Always
         image: us-docker.pkg.dev/qwiklabs-resources/healthcare-qwiklabs-resources/simhospital:latest
         ports:
           - containerPort: 8000
             protocol: TCP
             name: "port"
         command: ["/health/simulator"]
         args: ["-output=mllp", "-mllp_destination=$(kubectl get svc | grep mllp-adapter | awk {print'$4'}):2575"]
EOF

kubectl get pods

cat <<EOF | kubectl replace --force -f -
apiVersion: v1
kind: Pod
metadata:
 labels:
   run: dataflow-pipeline
 name: dataflow-pipeline
spec:
 containers:
 - command:
   - /usr/local/openjdk-11/bin/java
   - -jar
   - /root/converter-0.1.0-all.jar
   - --pubSubSubscription=projects/${PROJECT_ID}/subscriptions/${HL7_SUB}
   - --readErrorPath=gs://${ERROR_BUCKET}read/read_error.txt
   - --writeErrorPath=gs://${ERROR_BUCKET}write/write_error.txt
   - --mappingErrorPath=gs://${ERROR_BUCKET}mapping/mapping_error.txt
   - --mappingPath=gs://${MAPPING_BUCKET}/mapping_configs/hl7v2_fhir_r4/configurations/main.textproto
   - --fhirStore=projects/${PROJECT_ID}/locations/${LOCATION}/datasets/${DATASET_ID}/fhirStores/${FHIR_STORE_ID}
   - --tempLocation=gs://${PROJECT_ID}-df-pipeline/temp
   - --runner=DataflowRunner
   - --project=${PROJECT_ID}
   - --region=${LOCATION}
   image: us-docker.pkg.dev/qwiklabs-resources/healthcare-qwiklabs-resources/dataflow-pipeline:v0.02
   imagePullPolicy: Always
   name: dataflow-pipeline
 restartPolicy: Never
EOF

gcloud dataflow jobs list --region ${LOCATION}

curl -X GET \
     -H "Authorization: Bearer "$(gcloud auth print-access-token) \
     -H "Content-Type: application/json; charset=utf-8" \
     "https://healthcare.googleapis.com/v1/projects/${PROJECT_ID}/locations/${LOCATION}/datasets/${DATASET_ID}/hl7V2Stores/${HL7_STORE_ID}/messages"

echo "${RED}${BOLD}Congratulations${RESET}" "${WHITE}${BOLD}for${RESET}" "${GREEN}${BOLD}Completing the Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#