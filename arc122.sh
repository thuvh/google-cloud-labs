
export PROJECT_ID=
export REGION=
export API_KEY=
export BUCKET_URI=gs://${PROJECT_ID}-bucket


OBJECTS=`gcloud storage objects list ${BUCKET_URI} --format="json(name)"`
gcloud storage objects update ${BUCKET_URI}/manif-des-sans-papiers.jpg --add-acl-grant=entity=AllUsers,role=READER

cat <<EOF > request.json
{
  "requests": [
    {
      "image": {
        "source": {
            "gcsImageUri": "${BUCKET_URI}/manif-des-sans-papiers.jpg"
        }
      },
      "features": [
        {
          "type": "TEXT_DETECTION",
          "maxResults": 10
        }
      ]
    }
  ]
}
EOF
curl -s -X POST -H "Content-Type: application/json" --data-binary @request.json  https://vision.googleapis.com/v1/images:annotate?key=${API_KEY}
curl -s -X POST -H "Content-Type: application/json" --data-binary @request.json  https://vision.googleapis.com/v1/images:annotate?key=${API_KEY} -o text-response.json
gsutil cp text-response.json ${BUCKET_URI}

cat <<EOF > request.json
{
  "requests": [
    {
      "image": {
        "source": {
            "gcsImageUri": "${BUCKET_URI}/manif-des-sans-papiers.jpg"
        }
      },
      "features": [
        {
          "type": "LANDMARK_DETECTION",
          "maxResults": 10
        }
      ]
    }
  ]
}
EOF
curl -s -X POST -H "Content-Type: application/json" --data-binary @request.json  https://vision.googleapis.com/v1/images:annotate?key=${API_KEY}
curl -s -X POST -H "Content-Type: application/json" --data-binary @request.json  https://vision.googleapis.com/v1/images:annotate?key=${API_KEY} -o landmark-response.json
gsutil cp landmark-response.json ${BUCKET_URI}

