#!/bin/bash

gcloud services enable container.googleapis.com
gcloud container clusters create demo-gke --num-nodes 3 --zone us-west1-b
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx  --type=LoadBalancer --port 80
kubectl create -f basic-ingress.yaml
