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

export PROJECT_ID=$(gcloud config get-value project)

gcloud config set project $PROJECT_ID

export REGION="${ZONE%-*}"

gcloud services enable compute.googleapis.com
gcloud services enable logging.googleapis.com
gcloud services enable monitoring.googleapis.com
gcloud services enable recaptchaenterprise.googleapis.com

gcloud compute firewall-rules create default-allow-health-check --direction=INGRESS --priority=1000 --network=default --action=ALLOW --rules=tcp:80 --source-ranges=130.211.0.0/22,35.191.0.0/16 --target-tags=allow-health-check

gcloud compute firewall-rules create allow-ssh --direction=INGRESS --priority=1000 --network=default --action=ALLOW --rules=tcp:22 --source-ranges=0.0.0.0/0 --target-tags=allow-health-check

gcloud compute instance-templates create lb-backend-template \
    --machine-type=n1-standard-1 \
    --region=$REGION \
    --network=default \
    --subnet=default \
    --tags=allow-health-check \
    --metadata=startup-script='#! /bin/bash
sudo apt-get update
sudo apt-get install apache2 -y
sudo a2ensite default-ssl
sudo a2enmod ssl
sudo su
vm_hostname="$(curl -H "Metadata-Flavor:Google" http://metadata.google.internal/computeMetadata/v1/instance/name)"
echo "Page served from: $vm_hostname" | tee /var/www/html/index.html'

sleep 40

gcloud beta compute instance-groups managed create lb-backend-example --project=$PROJECT_ID --base-instance-name=lb-backend-example --template=projects/$PROJECT_ID/global/instanceTemplates/lb-backend-template --size=1 --zone=$ZONE --default-action-on-vm-failure=repair --no-force-update-on-repair --standby-policy-mode=manual --list-managed-instances-results=PAGELESS && gcloud beta compute instance-groups managed set-autoscaling lb-backend-example --project=$PROJECT_ID --zone=$ZONE --mode=off --min-num-replicas=1 --max-num-replicas=10 --target-cpu-utilization=0.6 --cool-down-period=60

gcloud compute instance-groups set-named-ports lb-backend-example \
--named-ports http:80 \
--zone $ZONE

DEVSHELL_PROJECT_ID=$(gcloud config get-value project)
TOKEN=$(gcloud auth application-default print-access-token)

# Define cURL command for creating health check
curl -X POST -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "checkIntervalSec": 5,
    "description": "",
    "healthyThreshold": 2,
    "logConfig": {
      "enable": false
    },
    "name": "http-health-check",
    "tcpHealthCheck": {
      "port": 80,
      "proxyHeader": "NONE"
    },
    "timeoutSec": 5,
    "type": "TCP",
    "unhealthyThreshold": 2
  }' \
  "https://compute.googleapis.com/compute/beta/projects/$DEVSHELL_PROJECT_ID/global/healthChecks"

sleep 30

# Define cURL command for creating security policy
curl -X POST -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "description": "Default security policy for: http-backend",
    "name": "default-security-policy-for-backend-service-http-backend",
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

# Define cURL command for creating backend service
curl -X POST -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "backends": [
      {
        "balancingMode": "UTILIZATION",
        "capacityScaler": 1,
        "group": "projects/'"$DEVSHELL_PROJECT_ID"'/zones/'"$ZONE"'/instanceGroups/lb-backend-example",
        "maxUtilization": 0.8
      }
    ],
    "cdnPolicy": {
      "cacheKeyPolicy": {
        "includeHost": true,
        "includeProtocol": true,
        "includeQueryString": true
      },
      "cacheMode": "USE_ORIGIN_HEADERS",
      "negativeCaching": false,
      "serveWhileStale": 0
    },
    "compressionMode": "DISABLED",
    "connectionDraining": {
      "drainingTimeoutSec": 300
    },
    "description": "",
    "enableCDN": true,
    "healthChecks": [
      "projects/'"$DEVSHELL_PROJECT_ID"'/global/healthChecks/http-health-check"
    ],
    "loadBalancingScheme": "EXTERNAL_MANAGED",
    "localityLbPolicy": "ROUND_ROBIN",
    "logConfig": {
      "enable": true,
      "sampleRate": 1
    },
    "name": "http-backend",
    "portName": "http",
    "protocol": "HTTP",
    "securityPolicy": "projects/'"$DEVSHELL_PROJECT_ID"'/global/securityPolicies/default-security-policy-for-backend-service-http-backend",
    "sessionAffinity": "NONE",
    "timeoutSec": 30
  }' \
  "https://compute.googleapis.com/compute/beta/projects/$DEVSHELL_PROJECT_ID/global/backendServices"

sleep 30

# Define cURL command for setting security policy for backend service
curl -X POST -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "securityPolicy": "projects/'"$DEVSHELL_PROJECT_ID"'/global/securityPolicies/default-security-policy-for-backend-service-http-backend"
  }' \
  "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/global/backendServices/http-backend/setSecurityPolicy"

sleep 30

# Define cURL command for creating URL map
curl -X POST -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "defaultService": "projects/'"$DEVSHELL_PROJECT_ID"'/global/backendServices/http-backend",
    "name": "http-lb"
  }' \
  "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/global/urlMaps"

sleep 30

# Define cURL command for creating target HTTP proxy
curl -X POST -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "name": "http-lb-target-proxy",
    "urlMap": "projects/'"$DEVSHELL_PROJECT_ID"'/global/urlMaps/http-lb"
  }' \
  "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/global/targetHttpProxies"

sleep 30

# Define cURL command for creating forwarding rule (IPv4)
curl -X POST -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "IPProtocol": "TCP",
    "ipVersion": "IPV4",
    "loadBalancingScheme": "EXTERNAL_MANAGED",
    "name": "http-lb-forwarding-rule",
    "networkTier": "PREMIUM",
    "portRange": "80",
    "target": "projects/'"$DEVSHELL_PROJECT_ID"'/global/targetHttpProxies/http-lb-target-proxy"
  }' \
  "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/global/forwardingRules"

sleep 30

# Run the gcloud command and store the output in a variable using command substitution
TOKEN_KEY=$(gcloud recaptcha keys create --display-name=test-key-name \
  --web --allow-all-domains --integration-type=score --testing-score=0.5 \
  --waf-feature=session-token --waf-service=ca --format="value(name)")

# Extract the token key without the project and key path
TOKEN_KEY=$(echo "$TOKEN_KEY" | awk -F '/' '{print $NF}')

# Echo the token key
echo "Token key: $TOKEN_KEY"

RECAPTCHA_KEY=$(gcloud recaptcha keys create --display-name=challenge-page-key \
--web --allow-all-domains --integration-type=INVISIBLE \
--waf-feature=challenge-page --waf-service=ca --format="value(name)")

RECAPTCHA_KEY=$(echo "$RECAPTCHA_KEY" | awk -F '/' '{print $NF}' )

# Run the gcloud command to list VM instances and filter by name
INSTANCE_NAME=$(gcloud compute instances list --format="value(name)" \
  --filter="name~^lb-backend-example" | head -n 1)

# Echo the instance name
echo "Instance name: $INSTANCE_NAME"

cat > prepare_disk.sh <<'EOF_END'
export TOKEN_KEY="$TOKEN_KEY"

cd /var/www/html/

sudo tee index.html > /dev/null <<HTML_CONTENT
<!doctype html>
<html>
<head>
  <title>ReCAPTCHA Session Token</title>
  <script src="https://www.google.com/recaptcha/enterprise.js?render=$TOKEN_KEY&waf=session" async defer></script>
</head>
<body>
  <h1>Main Page</h1>
  <p><a href="/good-score.html">Visit allowed link</a></p>
  <p><a href="/bad-score.html">Visit blocked link</a></p>
  <p><a href="/median-score.html">Visit redirect link</a></p>
</body>
</html>
HTML_CONTENT

sudo tee good-score.html > /dev/null <<GOOD_SCORE_CONTENT
<!DOCTYPE html>
<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=windows-1252">
</head>
<body>
  <h1>Congrats! You have a good score!!</h1>
</body>
</html>
GOOD_SCORE_CONTENT

sudo tee bad-score.html > /dev/null <<BAD_SCORE_CONTENT
<!DOCTYPE html>
<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=windows-1252">
</head>
<body>
  <h1>Sorry, You have a bad score!</h1>
</body>
</html>
BAD_SCORE_CONTENT

sudo tee median-score.html > /dev/null <<MEDIAN_SCORE_CONTENT
<!DOCTYPE html>
<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=windows-1252">
</head>
<body>
  <h1>You have a median score that we need a second verification.</h1>
</body>
</html>
MEDIAN_SCORE_CONTENT
EOF_END

gcloud compute scp prepare_disk.sh $INSTANCE_NAME:/tmp --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet

gcloud compute ssh $INSTANCE_NAME --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet --command="export TOKEN_KEY=$TOKEN_KEY && bash /tmp/prepare_disk.sh"

gcloud compute security-policies create recaptcha-policy \
    --description "policy for bot management"

gcloud compute security-policies update recaptcha-policy \
  --recaptcha-redirect-site-key "$RECAPTCHA_KEY"

gcloud compute security-policies rules create 2000 \
    --security-policy recaptcha-policy\
    --expression "request.path.matches('good-score.html') &&    token.recaptcha_session.score > 0.4"\
    --action allow

gcloud compute security-policies rules create 3000 \
    --security-policy recaptcha-policy\
    --expression "request.path.matches('bad-score.html') && token.recaptcha_session.score < 0.6"\
    --action "deny-403"

gcloud compute security-policies rules create 1000 \
    --security-policy recaptcha-policy\
    --expression "request.path.matches('median-score.html') && token.recaptcha_session.score == 0.5"\
    --action redirect \
    --redirect-type google-recaptcha

gcloud compute backend-services update http-backend \
    --security-policy recaptcha-policy --global

LB_IP_ADDRESS=$(gcloud compute forwarding-rules describe http-lb-forwarding-rule --global --format="value(IPAddress)")

echo $LB_IP_ADDRESS

gcloud logging read "resource.type:(http_load_balancer) AND jsonPayload.enforcedSecurityPolicy.name:(recaptcha-policy)" --project=$DEVSHELL_PROJECT_ID --format=json

gcloud logging read "resource.type:(http_load_balancer) AND jsonPayload.enforcedSecurityPolicy.name:(recaptcha-policy)" --project=$DEVSHELL_PROJECT_ID --format=json

echo "http://$LB_IP_ADDRESS/index.html"

echo "${RED}${BOLD}Congratulations${RESET}" "${WHITE}${BOLD}for${RESET}" "${GREEN}${BOLD}Completing the Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#