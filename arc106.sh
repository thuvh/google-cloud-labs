export REGION=
export PROJECT_ID=
export BUCKET_NAME=
export BIGQUERY_DATASET_NAME=
export BIGQUERY_TABLE_NAME=
export PUBSUB_TOPIC_NAME=
export DATAFLOW_JOB_NAME=

gcloud services enable dataflow.googleapis.com pubsub.googleapis.com

gsutil mb gs://$BUCKET_NAME/

bq mk --location us $BIGQUERY_DATASET_NAME
bq mk \
--time_partitioning_field timestamp \
--schema timestamp:timestamp,data:string -t $BIGQUERY_DATASET_NAME.$BIGQUERY_TABLE_NAME

gcloud pubsub topics create $PUBSUB_TOPIC_NAME
gcloud pubsub subscriptions create $PUBSUB_TOPIC_NAME-sub --topic $PUBSUB_TOPIC_NAME

gcloud dataflow jobs run $DATAFLOW_JOB_NAME \
    --gcs-location gs://dataflow-templates-$REGION/latest/PubSub_to_BigQuery \
    --region $REGION \
    --staging-location gs://$BUCKET_NAME/temp \
    --parameters inputTopic=projects/$PROJECT_ID/topics/$PUBSUB_TOPIC_NAME,outputTableSpec=$PROJECT_ID:$BIGQUERY_DATASET_NAME.$BIGQUERY_TABLE_NAME

gcloud pubsub topics publish $PUBSUB_TOPIC_NAME --message="{\"data\": \"73.4 F\"}"