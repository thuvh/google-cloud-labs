export PROJECT_ID=
export REGION=
export ZONE=

export PUBSUB_TOPIC=
export BUCKET_NAME=$PROJECT_ID
export MESSAGE_INPUT=

gcloud services enable \
    dataflow.googleapis.com \
    appengine.googleapis.com \
    cloudscheduler.googleapis.com

# Task 1
gcloud pubsub topics create $PUBSUB_TOPIC

# Taks 2
gcloud app create --region=$REGION
gcloud scheduler jobs create pubsub publisher-job \
    --schedule="* * * * *" \
    --topic=$PUBSUB_TOPIC \
    --message-body="$MESSAGE_INPUT"
gcloud scheduler jobs run publisher-job

# Task 3
gsutil mb gs://$BUCKET_NAME

# Task 4
git clone https://github.com/GoogleCloudPlatform/python-docs-samples.git

docker run -v ./python-docs-samples /python-docs-samples -it -e DEVSHELL_PROJECT_ID=$DEVSHELL_PROJECT_ID python:3.7 /bin/bash
cd /python-docs-samples/pubsub/streaming-analytics
pip install -U -r requirements.txt  # Install Apache Beam dependencies
python PubSubToGCS.py \
    --project=$PROJECT_ID \
    --region=$REGION \
    --input_topic=projects/$PROJECT_ID/topics/$PUBSUB_TOPIC \
    --output_path=gs://$BUCKET_NAME/samples/output \
    --runner=DataflowRunner \
    --window_size=2 \
    --num_shards=2 \
    --temp_location=gs://$BUCKET_NAME/temp
