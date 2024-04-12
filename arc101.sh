
export REGION=
export PROJECT_ID=
export BUCKET_NAME=
export USER2=

gcloud storage buckets create gs://$BUCKET_NAME --location=$REGION
gcloud projects add-iam-policy-binding $PROJECT_ID --member user:$USER2 --role='roles/storage.objectViewer' 

export PUB_SUB_NAME=
gcloud pubsub topics create $PUB_SUB_NAME

export FUNC_NAME=
export FUNC_ENTRY_POINT_NAME=

gcloud services enable cloudfunctions.googleapis.com artifactregistry.googleapis.com

mkdir code && cd code

cat <<EOF >> index.js
/* globals exports, require */
//jshint strict: false
//jshint esversion: 6
"use strict";
const crc32 = require("fast-crc32c");
const { Storage } = require('@google-cloud/storage');
const gcs = new Storage();
const { PubSub } = require('@google-cloud/pubsub');
const imagemagick = require("imagemagick-stream");

exports.${FUNC_ENTRY_POINT_NAME} = (event, context) => {
  const fileName = event.name;
  const bucketName = event.bucket;
  const size = "64x64"
  const bucket = gcs.bucket(bucketName);
  const topicName = "$PUB_SUB_NAME";
  const pubsub = new PubSub();
  if ( fileName.search("64x64_thumbnail") == -1 ){
    // doesn't have a thumbnail, get the filename extension
    var filename_split = fileName.split('.');
    var filename_ext = filename_split[filename_split.length - 1];
    var filename_without_ext = fileName.substring(0, fileName.length - filename_ext.length );
    if (filename_ext.toLowerCase() == 'png' || filename_ext.toLowerCase() == 'jpg'){
      // only support png and jpg at this point
      console.log(`Processing Original: gs://${bucketName}/${fileName}`);
      const gcsObject = bucket.file(fileName);
      let newFilename = filename_without_ext + size + '_thumbnail.' + filename_ext;
      let gcsNewObject = bucket.file(newFilename);
      let srcStream = gcsObject.createReadStream();
      let dstStream = gcsNewObject.createWriteStream();
      let resize = imagemagick().resize(size).quality(90);
      srcStream.pipe(resize).pipe(dstStream);
      return new Promise((resolve, reject) => {
        dstStream
          .on("error", (err) => {
            console.log(`Error: ${err}`);
            reject(err);
          })
          .on("finish", () => {
            console.log(`Success: ${fileName} → ${newFilename}`);
              // set the content-type
              gcsNewObject.setMetadata(
              {
                contentType: 'image/'+ filename_ext.toLowerCase()
              }, function(err, apiResponse) {});
              pubsub
                .topic(topicName)
                .publishMessage({data: Buffer.from(newFilename)})
                .then(messageId => {
                  console.log(`Message ${messageId} published.`);
                })
                .catch(err => {
                  console.error('ERROR:', err);
                });
          });
      });
    }
    else {
      console.log(`gs://${bucketName}/${fileName} is not an image I can handle`);
    }
  }
  else {
    console.log(`gs://${bucketName}/${fileName} already has a thumbnail`);
  }
};
EOF

cat <<EOF >> package.json 
{
  "name": "thumbnails",
  "version": "1.0.0",
  "description": "Create Thumbnail of uploaded image",
  "scripts": {
    "start": "node index.js"
  },
  "dependencies": {
    "@google-cloud/functions-framework": "^3.0.0",
    "@google-cloud/pubsub": "^2.0.0",
    "@google-cloud/storage": "^5.0.0",
    "fast-crc32c": "1.0.4",
    "imagemagick-stream": "4.1.1"
  },
  "devDependencies": {},
  "engines": {
    "node": ">=4.3.2"
  }
}
EOF

export PROJECT_NUMBER=`gcloud projects describe $PROJECT_ID --format='value(projectNumber)'`

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member=serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com \
    --role=roles/eventarc.eventReceiver \
    --role=roles/eventarc.serviceAgent

export SERVICE_ACCOUNT="$(gsutil kms serviceaccount -p $PROJECT_ID)"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${SERVICE_ACCOUNT}" \
    --role='roles/pubsub.publisher'

gcloud functions deploy $FUNC_NAME \
--runtime=nodejs14 \
--region=$REGION \
--source=. \
--entry-point=$FUNC_ENTRY_POINT_NAME \
--trigger-bucket=gs://$BUCKET_NAME 

curl -O https://storage.googleapis.com/cloud-training/arc101/travel.jpg

gsutil cp travel.jpg gs://$BUCKET_NAME

# TODO: 
https://cloud.google.com/monitoring/alerts/using-alerting-api
https://cloud.google.com/monitoring/alerts/using-channels-api
https://cloud.google.com/sdk/gcloud/reference/beta/monitoring/channels/create