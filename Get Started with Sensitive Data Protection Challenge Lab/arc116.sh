clear

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

# Array of color codes excluding black and white
TEXT_COLORS=($RED $GREEN $YELLOW $BLUE $MAGENTA $CYAN)
BG_COLORS=($BG_RED $BG_GREEN $BG_YELLOW $BG_BLUE $BG_MAGENTA $BG_CYAN)

# Pick random colors
RANDOM_TEXT_COLOR=${TEXT_COLORS[$RANDOM % ${#TEXT_COLORS[@]}]}
RANDOM_BG_COLOR=${BG_COLORS[$RANDOM % ${#BG_COLORS[@]}]}

#----------------------------------------------------start--------------------------------------------------#

echo "${RANDOM_BG_COLOR}${RANDOM_TEXT_COLOR}${BOLD}Starting Execution${RESET}"

# Step 1: Create redact-request.json
echo "${BOLD}${RED}Creating redact-request.json file${RESET}"
cat > redact-request.json <<EOF_END
{
	"item": {
		"value": "Please update my records with the following information:\n Email address: foo@example.com,\nNational Provider Identifier: 1245319599"
	},
	"deidentifyConfig": {
		"infoTypeTransformations": {
			"transformations": [{
				"primitiveTransformation": {
					"replaceWithInfoTypeConfig": {}
				}
			}]
		}
	},
	"inspectConfig": {
		"infoTypes": [{
				"name": "EMAIL_ADDRESS"
			},
			{
				"name": "US_HEALTHCARE_NPI"
			}
		]
	}
}
EOF_END

# Step 2: Deidentify content using DLP API
echo "${BOLD}${GREEN}Calling DLP API to deidentify content${RESET}"
curl -s \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  https://dlp.googleapis.com/v2/projects/$DEVSHELL_PROJECT_ID/content:deidentify \
  -d @redact-request.json -o redact-response.txt

# Step 3: Upload result to Cloud Storage
echo "${BOLD}${YELLOW}Uploading deidentified content to GCS${RESET}"
gsutil cp redact-response.txt gs://$DEVSHELL_PROJECT_ID-redact

# Step 4: Create structured data template
echo "${BOLD}${BLUE}Creating structured data deidentify template${RESET}"
cat <<EOF > template.json
{
  "deidentifyTemplate": {
    "deidentifyConfig": {
      "recordTransformations": {
        "fieldTransformations": [
          {
            "fields": [
              { "name": "bank name" },
              { "name": "zip code" }
            ],
            "primitiveTransformation": {
              "characterMaskConfig": {
                "maskingCharacter": "#"
              }
            }
          },
          {
            "fields": [
              { "name": "message" }
            ],
            "infoTypeTransformations": {
              "transformations": [
                {
                  "primitiveTransformation": {
                    "replaceWithInfoTypeConfig": {}
                  }
                }
              ]
            }
          }
        ]
      }
    },
    "displayName": "structured_data_template"
  },
  "locationId": "us",
  "templateId": "structured_data_template"
}
EOF

# Step 5: Upload structured template to DLP
echo "${BOLD}${MAGENTA}Uploading structured template to DLP API${RESET}"
curl -X POST -s \
-H "Authorization: Bearer $(gcloud auth application-default print-access-token)" \
-H "Content-Type: application/json" \
-d @template.json \
"https://dlp.googleapis.com/v2/projects/$DEVSHELL_PROJECT_ID/locations/us/deidentifyTemplates"

# Step 6: Create unstructured data template
echo "${BOLD}${CYAN}Creating unstructured data template${RESET}"
cat > template.json <<'EOF_END'
{
  "deidentifyTemplate": {
    "deidentifyConfig": {
      "infoTypeTransformations": {
        "transformations": [
          {
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
    "displayName": "unstructured_data_template"
  },
  "templateId": "unstructured_data_template"
}
EOF_END

# Step 7: Upload unstructured template to DLP
echo "${BOLD}${RED}Uploading unstructured template to DLP API${RESET}"
curl -X POST -s \
-H "Authorization: Bearer $(gcloud auth application-default print-access-token)" \
-H "Content-Type: application/json" \
-d @template.json \
"https://dlp.googleapis.com/v2/projects/$DEVSHELL_PROJECT_ID/locations/us/deidentifyTemplates"

# Step 8: Create job-configuration.json
echo "${BOLD}${GREEN}Creating job-configuration.json for scheduled DLP job${RESET}"
cat > job-configuration.json << EOM
{
  "triggerId": "dlp_job",
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
              "deidentifyTemplate": "projects/$DEVSHELL_PROJECT_ID/locations/us/deidentifyTemplates/unstructured_data_template",
              "structuredDeidentifyTemplate": "projects/$DEVSHELL_PROJECT_ID/locations/us/deidentifyTemplates/structured_data_template"
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

# Step 9: Send job configuration to DLP API
echo "${BOLD}${YELLOW}Sending job configuration to DLP API...${RESET}"
curl -s \
-H "Authorization: Bearer $(gcloud auth application-default print-access-token)" \
-H "Content-Type: application/json" \
https://dlp.googleapis.com/v2/projects/$DEVSHELL_PROJECT_ID/locations/us/jobTriggers \
-d @job-configuration.json

# Step 10: Wait for 15 seconds to ensure the job trigger is ready
echo "${BOLD}${MAGENTA}Waiting 60 seconds to ensure job trigger is ready${RESET}"
echo
for ((i=60; i>=0; i--)); do
  echo -ne "\r${BOLD}${CYAN}Time remaining${RESET} $i ${BOLD}${CYAN}seconds${RESET}"
  sleep 1
done
echo -e "\n${BOLD}${GREEN}Done!${RESET}"
echo

# Step 11: Activate DLP job trigger
echo "${BOLD}${BLUE}Activating DLP job trigger...${RESET}"
curl --request POST \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "X-Goog-User-Project: $DEVSHELL_PROJECT_ID" \
  "https://dlp.googleapis.com/v2/projects/$DEVSHELL_PROJECT_ID/locations/us/jobTriggers/dlp_job:activate"

echo

# Function to display a random congratulatory message
function random_congrats() {
    MESSAGES=(
        "${GREEN}Congratulations For Completing The Lab! Keep up the great work!${RESET}"
        "${CYAN}Well done! Your hard work and effort have paid off!${RESET}"
        "${YELLOW}Amazing job! You’ve successfully completed the lab!${RESET}"
        "${BLUE}Outstanding! Your dedication has brought you success!${RESET}"
        "${MAGENTA}Great work! You’re one step closer to mastering this!${RESET}"
        "${RED}Fantastic effort! You’ve earned this achievement!${RESET}"
        "${CYAN}Congratulations! Your persistence has paid off brilliantly!${RESET}"
        "${GREEN}Bravo! You’ve completed the lab with flying colors!${RESET}"
        "${YELLOW}Excellent job! Your commitment is inspiring!${RESET}"
        "${BLUE}You did it! Keep striving for more successes like this!${RESET}"
        "${MAGENTA}Kudos! Your hard work has turned into a great accomplishment!${RESET}"
        "${RED}You’ve smashed it! Completing this lab shows your dedication!${RESET}"
        "${CYAN}Impressive work! You’re making great strides!${RESET}"
        "${GREEN}Well done! This is a big step towards mastering the topic!${RESET}"
        "${YELLOW}You nailed it! Every step you took led you to success!${RESET}"
        "${BLUE}Exceptional work! Keep this momentum going!${RESET}"
        "${MAGENTA}Fantastic! You’ve achieved something great today!${RESET}"
        "${RED}Incredible job! Your determination is truly inspiring!${RESET}"
        "${CYAN}Well deserved! Your effort has truly paid off!${RESET}"
        "${GREEN}You’ve got this! Every step was a success!${RESET}"
        "${YELLOW}Nice work! Your focus and effort are shining through!${RESET}"
        "${BLUE}Superb performance! You’re truly making progress!${RESET}"
        "${MAGENTA}Top-notch! Your skill and dedication are paying off!${RESET}"
        "${RED}Mission accomplished! This success is a reflection of your hard work!${RESET}"
        "${CYAN}You crushed it! Keep pushing towards your goals!${RESET}"
        "${GREEN}You did a great job! Stay motivated and keep learning!${RESET}"
        "${YELLOW}Well executed! You’ve made excellent progress today!${RESET}"
        "${BLUE}Remarkable! You’re on your way to becoming an expert!${RESET}"
        "${MAGENTA}Keep it up! Your persistence is showing impressive results!${RESET}"
        "${RED}This is just the beginning! Your hard work will take you far!${RESET}"
        "${CYAN}Terrific work! Your efforts are paying off in a big way!${RESET}"
        "${GREEN}You’ve made it! This achievement is a testament to your effort!${RESET}"
        "${YELLOW}Excellent execution! You’re well on your way to mastering the subject!${RESET}"
        "${BLUE}Wonderful job! Your hard work has definitely paid off!${RESET}"
        "${MAGENTA}You’re amazing! Keep up the awesome work!${RESET}"
        "${RED}What an achievement! Your perseverance is truly admirable!${RESET}"
        "${CYAN}Incredible effort! This is a huge milestone for you!${RESET}"
        "${GREEN}Awesome! You’ve done something incredible today!${RESET}"
        "${YELLOW}Great job! Keep up the excellent work and aim higher!${RESET}"
        "${BLUE}You’ve succeeded! Your dedication is your superpower!${RESET}"
        "${MAGENTA}Congratulations! Your hard work has brought great results!${RESET}"
        "${RED}Fantastic work! You’ve taken a huge leap forward today!${RESET}"
        "${CYAN}You’re on fire! Keep up the great work!${RESET}"
        "${GREEN}Well deserved! Your efforts have led to success!${RESET}"
        "${YELLOW}Incredible! You’ve achieved something special!${RESET}"
        "${BLUE}Outstanding performance! You’re truly excelling!${RESET}"
        "${MAGENTA}Terrific achievement! Keep building on this success!${RESET}"
        "${RED}Bravo! You’ve completed the lab with excellence!${RESET}"
        "${CYAN}Superb job! You’ve shown remarkable focus and effort!${RESET}"
        "${GREEN}Amazing work! You’re making impressive progress!${RESET}"
        "${YELLOW}You nailed it again! Your consistency is paying off!${RESET}"
        "${BLUE}Incredible dedication! Keep pushing forward!${RESET}"
        "${MAGENTA}Excellent work! Your success today is well earned!${RESET}"
        "${RED}You’ve made it! This is a well-deserved victory!${RESET}"
        "${CYAN}Wonderful job! Your passion and hard work are shining through!${RESET}"
        "${GREEN}You’ve done it! Keep up the hard work and success will follow!${RESET}"
        "${YELLOW}Great execution! You’re truly mastering this!${RESET}"
        "${BLUE}Impressive! This is just the beginning of your journey!${RESET}"
        "${MAGENTA}You’ve achieved something great today! Keep it up!${RESET}"
        "${RED}You’ve made remarkable progress! This is just the start!${RESET}"
    )

    RANDOM_INDEX=$((RANDOM % ${#MESSAGES[@]}))
    echo -e "${BOLD}${MESSAGES[$RANDOM_INDEX]}"
}

# Display a random congratulatory message
random_congrats

echo -e "\n"  # Adding one blank line

cd

remove_files() {
    # Loop through all files in the current directory
    for file in *; do
        # Check if the file name starts with "gsp", "arc", or "shell"
        if [[ "$file" == gsp* || "$file" == arc* || "$file" == shell* ]]; then
            # Check if it's a regular file (not a directory)
            if [[ -f "$file" ]]; then
                # Remove the file and echo the file name
                rm "$file"
                echo "File removed: $file"
            fi
        fi
    done
}

remove_files
