
export PROJECT_ID=
export API_KEY=
export INSTANCE_NAME=

gcloud compute instances list

export ZONE=

gcloud compute ssh ${INSTANCE_NAME} --zone $ZONE

# Task 2
var apiEndpoint = 'https://language.googleapis.com/v1/documents:analyzeSentiment?key=' + apiKey;

export PROJECT_ID=
export API_KEY=

# other
cat > analyze-request.json <<EOF
{
  "document":{
    "type":"PLAIN_TEXT",
    "content": "Google, headquartered in Mountain View, unveiled the new Android phone at the Consumer Electronic Show.  Sundar Pichai said in his keynote that users love their new Android phones."
  },
  "encodingType": "UTF8"
}
EOF

curl "https://language.googleapis.com/v1/documents:analyzeSyntax?key=${API_KEY}" \
  -s -X POST -H "Content-Type: application/json" --data-binary @analyze-request.json > analyze-response.txt

cat > multi-nl-request.json <<EOF
{
  "document":{
    "type":"PLAIN_TEXT",
    "content":"Le bureau japonais de Google est situé à Roppongi Hills, Tokyo."
  }
}
EOF

curl "https://language.googleapis.com/v1/documents:analyzeEntities?key=${API_KEY}" \
  -s -X POST -H "Content-Type: application/json" --data-binary @multi-nl-request.json > multi-response.txt
