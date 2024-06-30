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

gcloud compute instance-templates create instance-template-1 --project=$DEVSHELL_PROJECT_ID --machine-type=e2-micro --network-interface=network=default,network-tier=PREMIUM --metadata=^,@^startup-script=\#\ Copyright\ 2021\ Google\ LLC$'\n'\#$'\n'\#\ Licensed\ under\ the\ Apache\ License,\ Version\ 2.0\ \(the\ \"License\"\)\;$'\n'\#\ you\ may\ not\ use\ this\ file\ except\ in\ compliance\ with\ the\ License.\#\ You\ may\ obtain\ a\ copy\ of\ the\ License\ at$'\n'\#$'\n'\#\ http://www.apache.org/licenses/LICENSE-2.0$'\n'\#$'\n'\#\ Unless\ required\ by\ applicable\ law\ or\ agreed\ to\ in\ writing,\ software$'\n'\#\ distributed\ under\ the\ License\ is\ distributed\ on\ an\ \"AS\ IS\"\ BASIS,$'\n'\#\ WITHOUT\ WARRANTIES\ OR\ CONDITIONS\ OF\ ANY\ KIND,\ either\ express\ or\ implied.$'\n'\#\ See\ the\ License\ for\ the\ specific\ language\ governing\ permissions\ and$'\n'\#\ limitations\ under\ the\ License.$'\n'sudo\ apt-get\ -y\ update$'\n'sudo\ apt-get\ -y\ install\ git$'\n'sudo\ apt-get\ -y\ install\ virtualenv$'\n'git\ clone\ https://github.com/GoogleCloudPlatform/python-docs-samples$'\n'cd\ python-docs-samples/iap$'\n'virtualenv\ venv\ -p\ python3$'\n'source\ venv/bin/activate$'\n'pip\ install\ -r\ requirements.txt$'\n'cat\ example_gce_backend.py\ \|$'\n'sed\ -e\ \"s/YOUR_BACKEND_SERVICE_ID/\$\(gcloud\ compute\ backend-services\ describe\ my-backend-service\ --global\ --format=\"value\(id\)\"\)/g\"\ \|$'\n'\ \ \ \ sed\ -e\ \"s/YOUR_PROJECT_ID/\$\(gcloud\ config\ get-value\ account\ \|\ tr\ -cd\ \"\[0-9\]\"\)/g\"\ \>\ real_backend.py$'\n'gunicorn\ real_backend:app\ -b\ 0.0.0.0:80,@enable-oslogin=true --maintenance-policy=MIGRATE --provisioning-model=STANDARD --scopes=https://www.googleapis.com/auth/compute.readonly,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/trace.append,https://www.googleapis.com/auth/devstorage.read_only --tags=http-server --create-disk=auto-delete=yes,boot=yes,device-name=instance-template-1,image=projects/debian-cloud/global/images/debian-11-bullseye-v20231212,mode=rw,size=10,type=pd-standard --no-shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring --reservation-affinity=any

gcloud beta compute instance-groups managed create my-managed-instance-group --project=$DEVSHELL_PROJECT_ID --base-instance-name=my-managed-instance-group --size=1 --template=projects/$DEVSHELL_PROJECT_ID/global/instanceTemplates/instance-template-1 --zones=$REGION-c,$REGION-f,$REGION-b --target-distribution-shape=EVEN --instance-redistribution-type=PROACTIVE --list-managed-instances-results=PAGELESS --no-force-update-on-repair --default-action-on-vm-failure=repair --standby-policy-mode=manual && gcloud beta compute instance-groups managed set-autoscaling my-managed-instance-group --project=$DEVSHELL_PROJECT_ID --region=$REGION --cool-down-period=60 --max-num-replicas=3 --min-num-replicas=1 --mode=off --target-cpu-utilization=0.6

gcloud compute addresses create static-ip --global --project=$DEVSHELL_PROJECT_ID

openssl genrsa -out PRIVATE_KEY_FILE 2048

cat > ssl_config <<EOF_END
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
EOF_END

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

PROJECT_ID=$(gcloud config get-value project)
TOKEN=$(gcloud auth application-default print-access-token)

curl -X POST -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "checkIntervalSec": 5,
    "description": "",
    "healthyThreshold": 2,
    "httpHealthCheck": {
      "host": "",
      "port": 80,
      "proxyHeader": "NONE",
      "requestPath": "/"
    },
    "logConfig": {
      "enable": false
    },
    "name": "my-health-check",
    "timeoutSec": 5,
    "type": "HTTP",
    "unhealthyThreshold": 2
  }' \
  "https://compute.googleapis.com/compute/beta/projects/$PROJECT_ID/global/healthChecks"

sleep 10

curl -X POST -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
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
  "https://compute.googleapis.com/compute/beta/projects/$PROJECT_ID/global/securityPolicies"

sleep 10

curl -X POST -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{
    \"backends\": [
      {
        \"balancingMode\": \"UTILIZATION\",
        \"capacityScaler\": 1,
        \"group\": \"projects/$PROJECT_ID/regions/$REGION/instanceGroups/my-managed-instance-group\",
        \"maxUtilization\": 0.8
      }
    ],
    \"connectionDraining\": {
      \"drainingTimeoutSec\": 300
    },
    \"description\": \"\",
    \"enableCDN\": false,
    \"healthChecks\": [
      \"projects/$PROJECT_ID/global/healthChecks/my-health-check\"
    ],
    \"loadBalancingScheme\": \"EXTERNAL_MANAGED\",
    \"localityLbPolicy\": \"ROUND_ROBIN\",
    \"logConfig\": {
      \"enable\": false
    },
    \"name\": \"my-backend-service\",
    \"portName\": \"http\",
    \"protocol\": \"HTTP\",
    \"securityPolicy\": \"projects/$PROJECT_ID/global/securityPolicies/default-security-policy-for-backend-service-my-backend-service\",
    \"sessionAffinity\": \"NONE\",
    \"timeoutSec\": 30
  }" \
  "https://compute.googleapis.com/compute/beta/projects/$PROJECT_ID/global/backendServices"

sleep 10

curl -X POST -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{
    \"securityPolicy\": \"projects/$PROJECT_ID/global/securityPolicies/default-security-policy-for-backend-service-my-backend-service\"
  }" \
  "https://compute.googleapis.com/compute/v1/projects/$PROJECT_ID/global/backendServices/my-backend-service/setSecurityPolicy"

sleep 10

curl -X POST -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{
    \"defaultService\": \"projects/$PROJECT_ID/global/backendServices/my-backend-service\",
    \"name\": \"my-load-balancer\"
  }" \
  "https://compute.googleapis.com/compute/v1/projects/$PROJECT_ID/global/urlMaps"

sleep 10

curl -X POST -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{
    \"name\": \"my-load-balancer-target-proxy\",
    \"quicOverride\": \"NONE\",
    \"sslCertificates\": [
      \"projects/$PROJECT_ID/global/sslCertificates/my-cert\"
    ],
    \"urlMap\": \"projects/$PROJECT_ID/global/urlMaps/my-load-balancer\"
  }" \
  "https://compute.googleapis.com/compute/v1/projects/$PROJECT_ID/global/targetHttpsProxies"

sleep 10

curl -X POST -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{
    \"IPAddress\": \"projects/$PROJECT_ID/global/addresses/static-ip\",
    \"IPProtocol\": \"TCP\",
    \"loadBalancingScheme\": \"EXTERNAL_MANAGED\",
    \"name\": \"my-load-balancer-forwarding-rule\",
    \"networkTier\": \"PREMIUM\",
    \"portRange\": \"443\",
    \"target\": \"projects/$PROJECT_ID/global/targetHttpsProxies/my-load-balancer-target-proxy\"
  }" \
  "https://compute.googleapis.com/compute/v1/projects/$PROJECT_ID/global/forwardingRules"

sleep 10

curl -X POST -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "namedPorts": [
      {
        "name": "http",
        "port": 80
      }
    ]
  }' \
  "https://compute.googleapis.com/compute/beta/projects/$PROJECT_ID/regions/$REGION/instanceGroups/my-managed-instance-group/setNamedPorts"

gcloud beta compute instance-groups managed rolling-action start-update my-managed-instance-group \
--project=$DEVSHELL_PROJECT_ID --type='proactive' --max-surge=0 --max-unavailable=3 --min-ready=0 --minimal-action='restart' --most-disruptive-allowed-action='restart' --replacement-method='substitute' --version=template=https://www.googleapis.com/compute/beta/projects/$DEVSHELL_PROJECT_ID/global/instanceTemplates/instance-template-1 --region=$REGION

gcloud compute --project=$DEVSHELL_PROJECT_ID firewall-rules delete default-allow-internal --quiet

sleep 10

gcloud compute --project=$DEVSHELL_PROJECT_ID firewall-rules create allow-iap-traffic --direction=INGRESS --priority=1000 --network=default --action=ALLOW --rules=tcp:80,tcp:78 --source-ranges=130.211.0.0/22,35.191.0.0/16

echo "${BG_RED}${BOLD}Congratulations For Completing The Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#