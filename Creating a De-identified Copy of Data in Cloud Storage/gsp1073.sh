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

echo "${BG_MAGENTA}${BOLD}Starting Execution...${RESET}"

cat > deidentify-template.json <<'EOF_END'
{
  "deidentifyTemplate": {
    "deidentifyConfig": {
      "infoTypeTransformations": {
        "transformations": [
          {
            "infoTypes": [
              {
                "name": ""
              }
            ],
            "primitiveTransformation": {
              "replaceWithInfoTypeConfig": {}
            }
          }
        ]
      }
    },
    "displayName": "deid_unstruct1 template"
  },
  "locationId": "global",
  "templateId": "deid_unstruct1"
}
EOF_END

# Make the API call to create the deidentify template
echo "${CYAN}${BOLD}Creating deidentify template with Google Cloud DLP API...${RESET}"
curl -s \
-H "Authorization: Bearer $(gcloud auth application-default print-access-token)" \
-H "Content-Type: application/json" \
https://dlp.googleapis.com/v2/projects/$DEVSHELL_PROJECT_ID/deidentifyTemplates \
-d @deidentify-template.json

cat > deidentify-template.json <<'EOF_END'
{
  "deidentifyTemplate": {
    "deidentifyConfig": {
      "recordTransformations": {
        "fieldTransformations": [
          {
            "fields": [
              { "name": "ssn" },
              { "name": "ccn" },
              { "name": "email" },
              { "name": "vin" },
              { "name": "id" },
              { "name": "agent_id" },
              { "name": "user_id" }
            ],
            "primitiveTransformation": {
              "replaceConfig": {
                "newValue": {
                  "stringValue": "[redacted]"
                }
              }
            }
          }
        ]
      }
    },
    "displayName": "deid_struct1 template"
  },
  "templateId": "deid_struct1",
  "locationId": "global"
}
EOF_END

# Make the API call to create the second deidentify template
echo "${CYAN}${BOLD}Creating deidentify template with Google Cloud DLP API...${RESET}"
curl -s \
-H "Authorization: Bearer $(gcloud auth application-default print-access-token)" \
-H "Content-Type: application/json" \
https://dlp.googleapis.com/v2/projects/$DEVSHELL_PROJECT_ID/deidentifyTemplates \
-d @deidentify-template.json

cat > job-configuration.json << EOM
{
  "triggerId": "DeID_Storage_Demo1",
  "jobTrigger": {
    "triggers": [
      {
        "schedule": {
          "recurrencePeriodDuration": "604800s"
        }
      }
    ],
    "inspectJob": {
      "actions": [
        {
          "deidentify": {
            "fileTypesToTransform": [
              "TEXT_FILE",
              "IMAGE",
              "CSV",
              "TSV"
            ],
            "transformationDetailsStorageConfig": {},
            "transformationConfig": {
              "deidentifyTemplate": "projects/$DEVSHELL_PROJECT_ID/locations/global/deidentifyTemplates/deid_unstruct1",
              "structuredDeidentifyTemplate": "projects/$DEVSHELL_PROJECT_ID/locations/global/deidentifyTemplates/deid_struct1"
            },
            "cloudStorageOutput": "gs://$DEVSHELL_PROJECT_ID-output"
          }
        }
      ],
      "inspectConfig": {
        "infoTypes": [
          {
            "name": "ADVERTISING_ID"
          },
          {
            "name": "AGE"
          },
          {
            "name": "ARGENTINA_DNI_NUMBER"
          },
          {
            "name": "AUSTRALIA_TAX_FILE_NUMBER"
          },
          {
            "name": "BELGIUM_NATIONAL_ID_CARD_NUMBER"
          },
          {
            "name": "BRAZIL_CPF_NUMBER"
          },
          {
            "name": "CANADA_SOCIAL_INSURANCE_NUMBER"
          },
          {
            "name": "CHILE_CDI_NUMBER"
          },
          {
            "name": "CHINA_RESIDENT_ID_NUMBER"
          },
          {
            "name": "COLOMBIA_CDC_NUMBER"
          },
          {
            "name": "CREDIT_CARD_NUMBER"
          },
          {
            "name": "CREDIT_CARD_TRACK_NUMBER"
          },
          {
            "name": "DATE_OF_BIRTH"
          },
          {
            "name": "DENMARK_CPR_NUMBER"
          },
          {
            "name": "EMAIL_ADDRESS"
          },
          {
            "name": "ETHNIC_GROUP"
          },
          {
            "name": "FDA_CODE"
          },
          {
            "name": "FINLAND_NATIONAL_ID_NUMBER"
          },
          {
            "name": "FRANCE_CNI"
          },
          {
            "name": "FRANCE_NIR"
          },
          {
            "name": "FRANCE_TAX_IDENTIFICATION_NUMBER"
          },
          {
            "name": "GENDER"
          },
          {
            "name": "GERMANY_IDENTITY_CARD_NUMBER"
          },
          {
            "name": "GERMANY_TAXPAYER_IDENTIFICATION_NUMBER"
          },
          {
            "name": "HONG_KONG_ID_NUMBER"
          },
          {
            "name": "IBAN_CODE"
          },
          {
            "name": "IMEI_HARDWARE_ID"
          },
          {
            "name": "INDIA_AADHAAR_INDIVIDUAL"
          },
          {
            "name": "INDIA_GST_INDIVIDUAL"
          },
          {
            "name": "INDIA_PAN_INDIVIDUAL"
          },
          {
            "name": "INDONESIA_NIK_NUMBER"
          },
          {
            "name": "IRELAND_PPSN"
          },
          {
            "name": "ISRAEL_IDENTITY_CARD_NUMBER"
          },
          {
            "name": "JAPAN_INDIVIDUAL_NUMBER"
          },
          {
            "name": "KOREA_RRN"
          },
          {
            "name": "MAC_ADDRESS"
          },
          {
            "name": "MEXICO_CURP_NUMBER"
          },
          {
            "name": "NETHERLANDS_BSN_NUMBER"
          },
          {
            "name": "NORWAY_NI_NUMBER"
          },
          {
            "name": "PARAGUAY_CIC_NUMBER"
          },
          {
            "name": "PASSPORT"
          },
          {
            "name": "PERSON_NAME"
          },
          {
            "name": "PERU_DNI_NUMBER"
          },
          {
            "name": "PHONE_NUMBER"
          },
          {
            "name": "POLAND_NATIONAL_ID_NUMBER"
          },
          {
            "name": "PORTUGAL_CDC_NUMBER"
          },
          {
            "name": "SCOTLAND_COMMUNITY_HEALTH_INDEX_NUMBER"
          },
          {
            "name": "SINGAPORE_NATIONAL_REGISTRATION_ID_NUMBER"
          },
          {
            "name": "SPAIN_CIF_NUMBER"
          },
          {
            "name": "SPAIN_DNI_NUMBER"
          },
          {
            "name": "SPAIN_NIE_NUMBER"
          },
          {
            "name": "SPAIN_NIF_NUMBER"
          },
          {
            "name": "SPAIN_SOCIAL_SECURITY_NUMBER"
          },
          {
            "name": "STORAGE_SIGNED_URL"
          },
          {
            "name": "STREET_ADDRESS"
          },
          {
            "name": "SWEDEN_NATIONAL_ID_NUMBER"
          },
          {
            "name": "SWIFT_CODE"
          },
          {
            "name": "THAILAND_NATIONAL_ID_NUMBER"
          },
          {
            "name": "TURKEY_ID_NUMBER"
          },
          {
            "name": "UK_NATIONAL_HEALTH_SERVICE_NUMBER"
          },
          {
            "name": "UK_NATIONAL_INSURANCE_NUMBER"
          },
          {
            "name": "UK_TAXPAYER_REFERENCE"
          },
          {
            "name": "URUGUAY_CDI_NUMBER"
          },
          {
            "name": "US_BANK_ROUTING_MICR"
          },
          {
            "name": "US_EMPLOYER_IDENTIFICATION_NUMBER"
          },
          {
            "name": "US_HEALTHCARE_NPI"
          },
          {
            "name": "US_INDIVIDUAL_TAXPAYER_IDENTIFICATION_NUMBER"
          },
          {
            "name": "US_SOCIAL_SECURITY_NUMBER"
          },
          {
            "name": "VEHICLE_IDENTIFICATION_NUMBER"
          },
          {
            "name": "VENEZUELA_CDI_NUMBER"
          },
          {
            "name": "WEAK_PASSWORD_HASH"
          },
          {
            "name": "AUTH_TOKEN"
          },
          {
            "name": "AWS_CREDENTIALS"
          },
          {
            "name": "AZURE_AUTH_TOKEN"
          },
          {
            "name": "BASIC_AUTH_HEADER"
          },
          {
            "name": "ENCRYPTION_KEY"
          },
          {
            "name": "GCP_API_KEY"
          },
          {
            "name": "GCP_CREDENTIALS"
          },
          {
            "name": "JSON_WEB_TOKEN"
          },
          {
            "name": "HTTP_COOKIE"
          },
          {
            "name": "XSRF_TOKEN"
          }
        ],
        "minLikelihood": "POSSIBLE"
      },
      "storageConfig": {
        "cloudStorageOptions": {
          "filesLimitPercent": 100,
          "fileTypes": [
            "TEXT_FILE",
            "IMAGE",
            "WORD",
            "PDF",
            "AVRO",
            "CSV",
            "TSV",
            "EXCEL",
            "POWERPOINT"
          ],
          "fileSet": {
            "regexFileSet": {
              "bucketName": "$DEVSHELL_PROJECT_ID-input",
              "includeRegex": [],
              "excludeRegex": []
            }
          }
        }
      }
    },
    "status": "HEALTHY"
  }
}
EOM

# Make the API call to create the job trigger
echo "${CYAN}${BOLD}Creating job trigger for scheduled deidentification...${RESET}"
curl -s \
-H "Authorization: Bearer $(gcloud auth application-default print-access-token)" \
-H "Content-Type: application/json" \
https://dlp.googleapis.com/v2/projects/$DEVSHELL_PROJECT_ID/locations/global/jobTriggers \
-d @job-configuration.json

# Provide link to deidentification template edit page
echo "${MAGENTA}${BOLD}Deidentification Template Successfully Created! Edit the template here: ${RESET}"
echo "https://console.cloud.google.com/security/sensitive-data-protection/projects/$DEVSHELL_PROJECT_ID/locations/global/deidentifyTemplates/deid_struct1/edit?project=$DEVSHELL_PROJECT_ID"

# Congratulations message
echo "${BG_RED}${BOLD}Congratulations For Completing The Lab!!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#