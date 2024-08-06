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

cat > app.rb <<'EOF_END'
require "functions_framework"
require "cgi"
require "json"

FunctionsFramework.http "hello_http" do |request|
  # The request parameter is a Rack::Request object.
  # See https://www.rubydoc.info/gems/rack/Rack/Request
  name = request.params["name"] ||
         (request.body.rewind && JSON.parse(request.body.read)["name"] rescue nil) ||
         "World"
  # Return the response body as a string.
  # You can also return a Rack::Response object, a Rack response array, or
  # a hash which will be JSON-encoded into a response.
  "Hello #{CGI.escape_html name}!"
end
EOF_END

cat > Gemfile <<'EOF_END'
source "https://rubygems.org"
gem "functions_framework", "~> 0.7"
EOF_END

cat > Gemfile.lock <<'EOF_END'
GEM
  remote: https://rubygems.org/
  specs:
    cloud_events (0.7.0)
    functions_framework (1.2.0)
      cloud_events (>= 0.7.0, < 2.a)
      puma (>= 4.3.0, < 6.a)
      rack (~> 2.1)
    nio4r (2.5.8)
    puma (5.6.5)
      nio4r (~> 2.0)
    rack (2.2.6.4)

PLATFORMS
  ruby
  x86_64-linux

DEPENDENCIES
  functions_framework (~> 1.2)

BUNDLED WITH
   2.4.6
EOF_END

gcloud functions deploy cf-demo \
  --gen2 \
  --runtime ruby33 \
  --entry-point hello_http \
  --source . \
  --region $REGION \
  --trigger-http \
  --allow-unauthenticated \
  --max-instances 5 \
  --quiet

echo "${BG_RED}${BOLD}Congratulations For Completing The Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#