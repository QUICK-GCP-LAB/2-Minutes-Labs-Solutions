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

cat > email-channel.json <<EOF_END
{
  "type": "email",
  "displayName": "quickgcplab",
  "description": "Awesome",
  "labels": {
    "email_address": "$USER_EMAIL"
  }
}
EOF_END

gcloud beta monitoring channels create --channel-content-from-file="email-channel.json"

# Get the channel ID
email_channel_info=$(gcloud beta monitoring channels list)
email_channel_id=$(echo "$email_channel_info" | grep -oP 'name: \K[^ ]+' | head -n 1)

cat > quickgcplab.json <<EOF_END
{
  "displayName": "quickgcplab",
  "userLabels": {},
  "conditions": [
    {
      "displayName": "VM Instance - CPU utilization",
      "conditionThreshold": {
        "filter": "resource.type = \"gce_instance\" AND metric.type = \"compute.googleapis.com/instance/cpu/utilization\"",
        "aggregations": [
          {
            "alignmentPeriod": "60s",
            "crossSeriesReducer": "REDUCE_NONE",
            "perSeriesAligner": "ALIGN_MEAN"
          }
        ],
        "comparison": "COMPARISON_GT",
        "duration": "0s",
        "trigger": {
          "count": 1
        },
        "thresholdValue": 0.2
      }
    },
    {
      "displayName": "VM Instance - CPU utilization",
      "conditionThreshold": {
        "filter": "resource.type = \"gce_instance\" AND metric.type = \"compute.googleapis.com/instance/cpu/utilization\"",
        "aggregations": [
          {
            "alignmentPeriod": "60s",
            "crossSeriesReducer": "REDUCE_NONE",
            "perSeriesAligner": "ALIGN_MEAN"
          }
        ],
        "comparison": "COMPARISON_GT",
        "duration": "0s",
        "trigger": {
          "count": 1
        },
        "thresholdValue": 0.2
      }
    }
  ],
  "alertStrategy": {
    "notificationPrompts": [
      "OPENED"
    ]
  },
  "combiner": "AND_WITH_MATCHING_RESOURCE",
  "enabled": true,
  "notificationChannels": [
    "$email_channel_id"
  ],
  "severity": "SEVERITY_UNSPECIFIED"
}
EOF_END

# Create the alert policy
gcloud alpha monitoring policies create --policy-from-file=quickgcplab.json

echo "${BG_RED}${BOLD}Congratulations For Completing The Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#