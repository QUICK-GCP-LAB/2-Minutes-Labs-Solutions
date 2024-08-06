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

cat > index.php <<'EOF_END'
<?php
use Google\CloudFunctions\FunctionsFramework;
use Psr\Http\Message\ServerRequestInterface;

// Register the function with Functions Framework.
// This enables omitting the `FUNCTIONS_SIGNATURE_TYPE=http` environment
// variable when deploying. The `FUNCTION_TARGET` environment variable should
// match the first parameter.
FunctionsFramework::http('helloHttp', 'helloHttp');

function helloHttp(ServerRequestInterface $request): string
{
  $name = 'World';
  $body = $request->getBody()->getContents();
  if (!empty($body)) {
    $json = json_decode($body, true);
    if (json_last_error() != JSON_ERROR_NONE) {
      throw new RuntimeException(sprintf(
        'Could not parse body: %s',
        json_last_error_msg()
      ));
    }
    $name = $json['name'] ?? $name;
  }
  $queryString = $request->getQueryParams();
  $name = $queryString['name'] ?? $name;

  return sprintf('Hello, %s!', htmlspecialchars($name));
}
EOF_END

cat > composer.json <<'EOF_END'
{
   "require": {
       "google/cloud-functions-framework": "^1.1"
   }
}
EOF_END

gcloud functions deploy cf-demo \
  --gen2 \
  --runtime php83 \
  --entry-point helloHttp \
  --source . \
  --region $REGION \
  --trigger-http \
  --allow-unauthenticated \
  --max-instances 5 \
  --quiet

echo "${BG_RED}${BOLD}Congratulations For Completing The Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#