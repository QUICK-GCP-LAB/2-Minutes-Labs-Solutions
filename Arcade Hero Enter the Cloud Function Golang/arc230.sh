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

cat > function.go <<EOF_END
package helloworld

import (
  "encoding/json"
  "fmt"
  "html"
  "net/http"

  "github.com/GoogleCloudPlatform/functions-framework-go/functions"
)

func init() {
   functions.HTTP("HelloHTTP", helloHTTP)
}

// helloHTTP is an HTTP Cloud Function with a request parameter.
func helloHTTP(w http.ResponseWriter, r *http.Request) {
  var d struct {
    Name string `json:"name"`
  }
  if err := json.NewDecoder(r.Body).Decode(&d); err != nil {
    fmt.Fprint(w, "Hello, World!")
    return
  }
  if d.Name == "" {
    fmt.Fprint(w, "Hello, World!")
    return
  }
  fmt.Fprintf(w, "Hello, %s!", html.EscapeString(d.Name))
}

EOF_END

echo "module example.com/mod" > go.mod

gcloud functions deploy cf-demo \
  --gen2 \
  --runtime go122 \
  --entry-point HelloHTTP \
  --source . \
  --region $REGION \
  --trigger-http \
  --allow-unauthenticated \
  --max-instances 5 \
  --quiet

  echo "${BG_RED}${BOLD}Congratulations For Completing The Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#