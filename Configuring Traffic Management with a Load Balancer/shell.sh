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

export PROJECT_ID=$(gcloud config get-value project)
export REGION="${ZONE_1%-*}"
export TOKEN=$(gcloud auth application-default print-access-token)

gcloud compute instances create utility-vm \
--zone $ZONE_1 \
--machine-type e2-medium \
--network-interface=private-network-ip=10.10.20.50,stack-type=IPV4_ONLY,subnet=subnet-a,no-address

sleep 60

gcloud compute ssh utility-vm --project=$DEVSHELL_PROJECT_ID --zone=$ZONE_1 --quiet --command 'curl 10.10.20.2 && curl 10.10.30.2'

gcloud compute networks subnets create my-proxy-subnet --region=$REGION --purpose=REGIONAL_MANAGED_PROXY --role=ACTIVE --network=my-internal-app --range=10.10.40.0/24

curl -X POST -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "checkIntervalSec": 10,
    "description": "",
    "healthyThreshold": 2,
    "logConfig": {
      "enable": false
    },
    "name": "blue-health-check",
    "tcpHealthCheck": {
      "port": 80,
      "proxyHeader": "NONE"
    },
    "timeoutSec": 5,
    "type": "TCP",
    "unhealthyThreshold": 3
  }' \
  "https://compute.googleapis.com/compute/beta/projects/$DEVSHELL_PROJECT_ID/regions/$REGION/healthChecks"

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
  "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/zones/$ZONE_1/instanceGroups/instance-group-1/setNamedPorts"

sleep 30

curl -X POST -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{
    \"backends\": [
      {
        \"balancingMode\": \"UTILIZATION\",
        \"capacityScaler\": 1,
        \"group\": \"projects/$DEVSHELL_PROJECT_ID/zones/$ZONE_1/instanceGroups/instance-group-1\",
        \"maxUtilization\": 0.8
      }
    ],
    \"connectionDraining\": {
      \"drainingTimeoutSec\": 300
    },
    \"description\": \"\",
    \"enableCDN\": false,
    \"healthChecks\": [
      \"projects/$DEVSHELL_PROJECT_ID/regions/$REGION/healthChecks/blue-health-check\"
    ],
    \"loadBalancingScheme\": \"INTERNAL_MANAGED\",
    \"localityLbPolicy\": \"ROUND_ROBIN\",
    \"name\": \"blue-service\",
    \"portName\": \"http\",
    \"protocol\": \"HTTP\",
    \"region\": \"projects/$DEVSHELL_PROJECT_ID/regions/$REGION\",
    \"sessionAffinity\": \"NONE\",
    \"timeoutSec\": 30
  }" \
  "https://compute.googleapis.com/compute/beta/projects/$DEVSHELL_PROJECT_ID/regions/$REGION/backendServices"

sleep 30 

curl -X POST -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "checkIntervalSec": 10,
    "description": "",
    "healthyThreshold": 2,
    "logConfig": {
      "enable": false
    },
    "name": "green-health-check",
    "tcpHealthCheck": {
      "port": 80,
      "proxyHeader": "NONE"
    },
    "timeoutSec": 5,
    "type": "TCP",
    "unhealthyThreshold": 3
  }' \
  "https://compute.googleapis.com/compute/beta/projects/$DEVSHELL_PROJECT_ID/regions/$REGION/healthChecks"

sleep 60

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
  "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/zones/$ZONE_2/instanceGroups/instance-group-2/setNamedPorts"

sleep 30

curl -X POST -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "backends": [
      {
        "balancingMode": "UTILIZATION",
        "capacityScaler": 1,
        "group": "projects/'$DEVSHELL_PROJECT_ID'/zones/'$ZONE_2'/instanceGroups/instance-group-2",
        "maxUtilization": 0.8
      }
    ],
    "connectionDraining": {
      "drainingTimeoutSec": 300
    },
    "description": "",
    "enableCDN": false,
    "healthChecks": [
      "projects/'$DEVSHELL_PROJECT_ID'/regions/'$REGION'/healthChecks/green-health-check"
    ],
    "loadBalancingScheme": "INTERNAL_MANAGED",
    "localityLbPolicy": "ROUND_ROBIN",
    "name": "green-service",
    "portName": "http",
    "protocol": "HTTP",
    "region": "projects/'$DEVSHELL_PROJECT_ID'/regions/'$REGION'",
    "sessionAffinity": "NONE",
    "timeoutSec": 30
  }' \
  "https://compute.googleapis.com/compute/beta/projects/$DEVSHELL_PROJECT_ID/regions/$REGION/backendServices"

sleep 30   
  
curl -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "defaultService": "projects/'$DEVSHELL_PROJECT_ID'/regions/'$REGION'/backendServices/blue-service",
    "hostRules": [
      {
        "hosts": ["*"],
        "pathMatcher": "matcher1"
      }
    ],
    "name": "my-ilb",
    "pathMatchers": [
      {
        "defaultService": "regions/'$REGION'/backendServices/blue-service",
        "name": "matcher1",
        "routeRules": [
          {
            "matchRules": [
              {
                "prefixMatch": "/"
              }
            ],
            "priority": 0,
            "routeAction": {
              "weightedBackendServices": [
                {
                  "backendService": "regions/'$REGION'/backendServices/blue-service",
                  "weight": 70
                },
                {
                  "backendService": "regions/'$REGION'/backendServices/green-service",
                  "weight": 30
                }
              ]
            }
          }
        ]
      }
    ],
    "region": "projects/'$DEVSHELL_PROJECT_ID'/regions/'$REGION'"
  }' \
  "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/regions/$REGION/urlMaps"

sleep 10  

curl -X POST -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d '{
      "name": "my-ilb-target-proxy",
      "region": "projects/'$DEVSHELL_PROJECT_ID'/regions/'$REGION'",
      "urlMap": "projects/'$DEVSHELL_PROJECT_ID'/regions/'$REGION'/urlMaps/my-ilb"
    }' \
    "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/regions/$REGION/targetHttpProxies"

sleep 10  

curl -X POST -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d '{
      "IPAddress": "10.10.30.5",
      "IPProtocol": "TCP",
      "allowGlobalAccess": false,
      "loadBalancingScheme": "INTERNAL_MANAGED",
      "name": "my-ilb-forwarding-rule",
      "networkTier": "PREMIUM",
      "portRange": "80",
      "region": "projects/'"$DEVSHELL_PROJECT_ID"'/regions/'"$REGION"'",
      "subnetwork": "projects/'"$DEVSHELL_PROJECT_ID"'/regions/'"$REGION"'/subnetworks/subnet-b",
      "target": "projects/'"$DEVSHELL_PROJECT_ID"'/regions/'"$REGION"'/targetHttpProxies/my-ilb-target-proxy"
    }' \
    "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/regions/$REGION/forwardingRules"

echo "${BG_RED}${BOLD}Congratulations For Completing The Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#