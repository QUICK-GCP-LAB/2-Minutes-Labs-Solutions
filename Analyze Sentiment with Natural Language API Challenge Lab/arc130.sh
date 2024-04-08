cat > analyze-request.json <<EOF_END
{
  "document":{
    "type":"PLAIN_TEXT",
    "content": "Google, headquartered in Mountain View, unveiled the new Android phone at the Consumer Electronic Show.  Sundar Pichai said in his keynote that users love their new Android phones."
  },
  "encodingType": "UTF8"
}
EOF_END

curl -s -H "Content-Type: application/json" \
-H "Authorization: Bearer $(gcloud auth print-access-token)" \
"https://language.googleapis.com/v1/documents:analyzeSyntax" \
-d @analyze-request.json > analyze-response.txt

cat > multi-nl-request.json <<EOF_END
{
  "document":{
    "type":"PLAIN_TEXT",
    "content":"Le bureau japonais de Google est situé à Roppongi Hills, Tokyo."
  }
}
EOF_END

curl -s -H "Content-Type: application/json" \
-H "Authorization: Bearer $(gcloud auth print-access-token)" \
"https://language.googleapis.com/v1/documents:analyzeEntities" \
-d @multi-nl-request.json > multi-response.txt