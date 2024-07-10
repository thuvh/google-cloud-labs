export PROJECT_ID=
export REGION=
export ZONE=

export NETWORK_TAG=http

gsutil mb -l $REGION gs://$PROJECT_ID
gsutil cp gs://spls/gsp301/install-web.sh gs://$PROJECT_ID/

gcloud compute instances create lab01 \
    --zone=$ZONE \
    --tags=$NETWORK_TAG \
    --metadata startup-script-url=gs://$PROJECT_ID/install-web.sh

gcloud compute firewall-rules create allow-http \
    --target-tags $NETWORK_TAG \
    --source-ranges 0.0.0.0/0 \
    --allow tcp:80
