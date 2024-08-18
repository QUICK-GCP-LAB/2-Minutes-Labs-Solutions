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

gcloud services enable iap.googleapis.com

gcloud compute instance-templates create instance-template-1 --project=$DEVSHELL_PROJECT_ID --machine-type=e2-micro --network-interface=network=default,network-tier=PREMIUM --metadata=^,@^startup-script=\#\ Copyright\ 2021\ Google\ LLC$'\n'\#$'\n'\#\ Licensed\ under\ the\ Apache\ License,\ Version\ 2.0\ \(the\ \"License\"\)\;$'\n'\#\ you\ may\ not\ use\ this\ file\ except\ in\ compliance\ with\ the\ License.\#\ You\ may\ obtain\ a\ copy\ of\ the\ License\ at$'\n'\#$'\n'\#\ http://www.apache.org/licenses/LICENSE-2.0$'\n'\#$'\n'\#\ Unless\ required\ by\ applicable\ law\ or\ agreed\ to\ in\ writing,\ software$'\n'\#\ distributed\ under\ the\ License\ is\ distributed\ on\ an\ \"AS\ IS\"\ BASIS,$'\n'\#\ WITHOUT\ WARRANTIES\ OR\ CONDITIONS\ OF\ ANY\ KIND,\ either\ express\ or\ implied.$'\n'\#\ See\ the\ License\ for\ the\ specific\ language\ governing\ permissions\ and$'\n'\#\ limitations\ under\ the\ License.$'\n'apt-get\ -y\ update$'\n'apt-get\ -y\ install\ git$'\n'apt-get\ -y\ install\ virtualenv$'\n'git\ clone\ https://github.com/GoogleCloudPlatform/python-docs-samples$'\n'cd\ python-docs-samples/iap$'\n'virtualenv\ venv\ -p\ python3$'\n'source\ venv/bin/activate$'\n'pip\ install\ -r\ requirements.txt$'\n'cat\ example_gce_backend.py\ \|$'\n'sed\ -e\ \"s/YOUR_BACKEND_SERVICE_ID/\$\(gcloud\ compute\ backend-services\ describe\ my-backend-service\ --global--format=\"value\(id\)\"\)/g\"\ \|$'\n'\ \ \ \ sed\ -e\ \"s/YOUR_PROJECT_ID/\$\(gcloud\ config\ get-value\ account\ \|\ tr\ -cd\ \"\[0-9\]\"\)/g\"\ \>\ real_backend.py$'\n'gunicorn\ real_backend:app\ -b\ 0.0.0.0:80,@enable-oslogin=true --maintenance-policy=MIGRATE --provisioning-model=STANDARD --tags=http-server --create-disk=auto-delete=yes,boot=yes,device-name=instance-template-1,image=projects/debian-cloud/global/images/debian-11-bullseye-v20230509,mode=rw,size=10,type=pd-balanced --no-shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring --reservation-affinity=any --scopes=https://www.googleapis.com/auth/cloud-platform,https://www.googleapis.com/auth/compute.readonly

gcloud beta compute health-checks create http my-health-check --project=$DEVSHELL_PROJECT_ID --port=80 --request-path=/ --proxy-header=NONE --no-enable-logging --check-interval=5 --timeout=5 --unhealthy-threshold=2 --healthy-threshold=2

gcloud beta compute instance-groups managed create my-managed-instance-group --project=$DEVSHELL_PROJECT_ID --base-instance-name=my-managed-instance-group --size=1 --template=instance-template-1 --region=$REGION --target-distribution-shape=EVEN --instance-redistribution-type=PROACTIVE --list-managed-instances-results=PAGELESS --health-check=my-health-check --initial-delay=300 --no-force-update-on-repair && gcloud beta compute instance-groups managed set-autoscaling my-managed-instance-group --project=$DEVSHELL_PROJECT_ID --region=$REGION --cool-down-period=60 --max-num-replicas=10 --min-num-replicas=1 --mode=off --target-cpu-utilization=0.6

openssl genrsa -out PRIVATE_KEY_FILE 2048

cat > ssl_config <<EOF
[req]
default_bits = 2048
req_extensions = extension_requirements
distinguished_name = dn_requirements
prompt = no
[extension_requirements]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
[dn_requirements]
countryName = US
stateOrProvinceName = CA
localityName = Mountain View
0.organizationName = Cloud
organizationalUnitName = Example
commonName = Test
EOF

openssl req -new -key PRIVATE_KEY_FILE \
 -out CSR_FILE \
 -config ssl_config

openssl x509 -req \
 -signkey PRIVATE_KEY_FILE \
 -in CSR_FILE \
 -out CERTIFICATE_FILE.pem \
 -extfile ssl_config \
 -extensions extension_requirements \
 -days 365

gcloud compute ssl-certificates create my-cert \
 --certificate=CERTIFICATE_FILE.pem \
 --private-key=PRIVATE_KEY_FILE \
 --global

curl -X POST \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer $(gcloud auth print-access-token)" \
     -d '{
       "description": "Default security policy for: my-backend-service",
       "name": "default-security-policy-for-backend-service-my-backend-service",
       "rules": [
         {
           "action": "allow",
           "match": {
             "config": {
               "srcIpRanges": [
                 "*"
               ]
             },
             "versionedExpr": "SRC_IPS_V1"
           },
           "priority": 2147483647
         },
         {
           "action": "throttle",
           "description": "Default rate limiting rule",
           "match": {
             "config": {
               "srcIpRanges": [
                 "*"
               ]
             },
             "versionedExpr": "SRC_IPS_V1"
           },
           "priority": 2147483646,
           "rateLimitOptions": {
             "conformAction": "allow",
             "enforceOnKey": "IP",
             "exceedAction": "deny(403)",
             "rateLimitThreshold": {
               "count": 500,
               "intervalSec": 60
             }
           }
         }
       ]
     }' \
     "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/global/securityPolicies"

sleep 30

curl -X POST \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer $(gcloud auth print-access-token)" \
     -d '{
       "backends": [
         {
           "balancingMode": "UTILIZATION",
           "capacityScaler": 1,
           "group": "projects/'"$DEVSHELL_PROJECT_ID"'/regions/'"$REGION"'/instanceGroups/my-managed-instance-group",
           "maxUtilization": 0.8
         }
       ],
       "connectionDraining": {
         "drainingTimeoutSec": 300
       },
       "description": "",
       "enableCDN": false,
       "healthChecks": [
         "projects/'"$DEVSHELL_PROJECT_ID"'/global/healthChecks/my-health-check"
       ],
       "ipAddressSelectionPolicy": "IPV4_ONLY",
       "loadBalancingScheme": "EXTERNAL_MANAGED",
       "localityLbPolicy": "ROUND_ROBIN",
       "logConfig": {
         "enable": false
       },
       "name": "my-backend-service",
       "portName": "http",
       "protocol": "HTTP",
       "securityPolicy": "projects/'"$DEVSHELL_PROJECT_ID"'/global/securityPolicies/default-security-policy-for-backend-service-my-backend-service",
       "sessionAffinity": "NONE",
       "timeoutSec": 30
     }' \
     "https://compute.googleapis.com/compute/beta/projects/$DEVSHELL_PROJECT_ID/global/backendServices"


sleep 60

curl -X POST \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer $(gcloud auth print-access-token)" \
     -d '{
       "securityPolicy": "projects/'"$DEVSHELL_PROJECT_ID"'/global/securityPolicies/default-security-policy-for-backend-service-my-backend-service"
     }' \
     "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/global/backendServices/my-backend-service/setSecurityPolicy"

sleep 60

curl -X POST \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer $(gcloud auth print-access-token)" \
     -d '{
       "defaultService": "projects/'"$DEVSHELL_PROJECT_ID"'/global/backendServices/my-backend-service",
       "name": "my-load-balancer"
     }' \
     "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/global/urlMaps"


sleep 30


curl -X POST \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer $(gcloud auth print-access-token)" \
     -d '{
       "name": "my-load-balancer-target-proxy",
       "urlMap": "projects/'"$DEVSHELL_PROJECT_ID"'/global/urlMaps/my-load-balancer"
     }' \
     "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/global/targetHttpProxies"

sleep 90

curl -X POST \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer $(gcloud auth print-access-token)" \
     -d '{
       "IPAddress": "projects/'"$DEVSHELL_PROJECT_ID"'/global/addresses/my-cert",
       "IPProtocol": "TCP",
       "loadBalancingScheme": "EXTERNAL_MANAGED",
       "name": "my-load-balancer-forwarding-rule",
       "networkTier": "PREMIUM",
       "portRange": "80",
       "target": "projects/'"$DEVSHELL_PROJECT_ID"'/global/targetHttpProxies/my-load-balancer-target-proxy"
     }' \
     "https://compute.googleapis.com/compute/beta/projects/$DEVSHELL_PROJECT_ID/global/forwardingRules"

sleep 30

curl -X POST \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer $(gcloud auth print-access-token)" \
     -d '{
       "namedPorts": [
         {
           "name": "http",
           "port": 80
         }
       ]
     }' \
     "https://compute.googleapis.com/compute/beta/projects/$DEVSHELL_PROJECT_ID/regions/$REGION/instanceGroups/my-managed-instance-group/setNamedPorts"
     
echo "${BG_RED}${BOLD}Congratulations For Completing The Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#
