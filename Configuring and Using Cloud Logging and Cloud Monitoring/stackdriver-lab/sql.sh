#!/bin/bash

gcloud services enable sql-component.googleapis.com
gcloud services enable sqladmin.googleapis.com
gcloud sql instances create demo-sql
gcloud sql databases create demo-db --instance demo-sql
gcloud sql users set-password root --instance demo-sql --password demo-pass
