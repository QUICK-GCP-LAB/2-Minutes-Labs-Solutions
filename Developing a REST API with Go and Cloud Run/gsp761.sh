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

gcloud services enable run.googleapis.com
gcloud services enable cloudbuild.googleapis.com

gcloud config set project $(gcloud projects list --format='value(PROJECT_ID)' --filter='qwiklabs-gcp')

git clone https://github.com/rosera/pet-theory.git && cd pet-theory/lab08

cat > main.go <<EOF
package main

import (
  "fmt"
  "log"
  "net/http"
  "os"
)

func main() {
  port := os.Getenv("PORT")
  if port == "" {
      port = "8080"
  }
  http.HandleFunc("/v1/", func(w http.ResponseWriter, r *http.Request) {
      fmt.Fprintf(w, "{status: 'running'}")
  })
  log.Println("Pets REST API listening on port", port)
  if err := http.ListenAndServe(":"+port, nil); err != nil {
      log.Fatalf("Error launching Pets REST API server: %v", err)
  }
}
EOF

cat > Dockerfile <<EOF
FROM gcr.io/distroless/base-debian12
WORKDIR /usr/src/app
COPY server .
CMD [ "/usr/src/app/server" ]
EOF

go build -o server

ls -la

gcloud builds submit \
  --tag gcr.io/$GOOGLE_CLOUD_PROJECT/rest-api:0.1

gcloud run deploy rest-api \
  --image gcr.io/$GOOGLE_CLOUD_PROJECT/rest-api:0.1 \
  --platform managed \
  --region $REGION \
  --allow-unauthenticated \
  --max-instances=2

gcloud firestore databases create --location nam5

cat > main.go <<'EOF_END'
package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"

	"cloud.google.com/go/firestore"
	"github.com/gorilla/handlers"
	"github.com/gorilla/mux"
	"google.golang.org/api/iterator"
)

  var client *firestore.Client

  func main() {
    var err error
    ctx := context.Background()
    client, err = firestore.NewClient(ctx, "\"Filled in at lab startup\"")
    if err != nil {
    log.Fatalf("Error initializing Cloud Firestore client: %v", err)
  }

  port := os.Getenv("PORT")
  if port == "" {
    port = "8080"
  }

  r := mux.NewRouter()
  r.HandleFunc("/v1/", rootHandler)
  r.HandleFunc("/v1/customer/{id}", customerHandler)

  log.Println("Pets REST API listening on port", port)
  cors := handlers.CORS(
    handlers.AllowedHeaders([]string{"X-Requested-With", "Authorization", "Origin"}),
    handlers.AllowedOrigins([]string{"https://storage.googleapis.com"}),
    handlers.AllowedMethods([]string{"GET", "HEAD", "POST", "OPTIONS", "PATCH", "CONNECT"}),
  )

	if err := http.ListenAndServe(":"+port, cors(r)); err != nil {
    log.Fatalf("Error launching Pets REST API server: %v", err)
	}
}

func rootHandler(w http.ResponseWriter, r *http.Request) {
  fmt.Fprintf(w, "{status: 'running'}")
}

func customerHandler(w http.ResponseWriter, r *http.Request) {
  id := mux.Vars(r)["id"]
  ctx := context.Background()
  customer, err := getCustomer(ctx, id)
  if err != nil {
    w.WriteHeader(http.StatusInternalServerError)
    fmt.Fprintf(w, `{"status": "fail", "data": '%s'}`, err)
    return
  }
  if customer == nil {
    w.WriteHeader(http.StatusNotFound)
    msg := fmt.Sprintf("`Customer \"%s\" not found`", id)
    fmt.Fprintf(w, fmt.Sprintf(`{"status": "fail", "data": {"title": %s}}`, msg))
    return
  }
  amount, err := getAmounts(ctx, customer)
  if err != nil {
    w.WriteHeader(http.StatusInternalServerError)
    fmt.Fprintf(w, `{"status": "fail", "data": "Unable to fetch amounts: %s"}`, err)
    return
  }
  data, err := json.Marshal(amount)
  if err != nil {
    w.WriteHeader(http.StatusInternalServerError)
    fmt.Fprintf(w, `{"status": "fail", "data": "Unable to fetch amounts: %s"}`, err)
    return
  }
  fmt.Fprintf(w, fmt.Sprintf(`{"status": "success", "data": %s}`, data))
}

type Customer struct {
  Email string `firestore:"email"`
  ID    string `firestore:"id"`
  Name  string `firestore:"name"`
  Phone string `firestore:"phone"`
}

func getCustomer(ctx context.Context, id string) (*Customer, error) {
  query := client.Collection("customers").Where("id", "==", id)
  iter := query.Documents(ctx)

  var c Customer
  for {
    doc, err := iter.Next()
    if err == iterator.Done {
	break
    }
    if err != nil {
	return nil, err
    }
    err = doc.DataTo(&c)
    if err != nil {
	return nil, err
    }
  }
  return &c, nil
}

func getAmounts(ctx context.Context, c *Customer) (map[string]int64, error) {
  if c == nil {
    return map[string]int64{}, fmt.Errorf("Customer should be non-nil: %v", c)
  }
  result := map[string]int64{
    "proposed": 0,
    "approved": 0,
    "rejected": 0,
  }
  query := client.Collection(fmt.Sprintf("customers/%s/treatments", c.Email))
  if query == nil {
    return map[string]int64{}, fmt.Errorf("Query is nil: %v", c)
  }
  iter := query.Documents(ctx)
  for {
    doc, err := iter.Next()
    if err == iterator.Done {
	break
    }
    if err != nil {
	return nil, err
    }
    treatment := doc.Data()
    result[treatment["status"].(string)] += treatment["cost"].(int64)
  }
  return result, nil
}
EOF_END

go build -o server

gcloud builds submit \
  --tag gcr.io/$GOOGLE_CLOUD_PROJECT/rest-api:0.2

echo "${BG_RED}${BOLD}Congratulations For Completing The Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#