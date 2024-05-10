export LOCATION=US
export PROJECT_ID=
export CLOUD_CONNECTION_ID=user_data_connection
export BIGQUERY_DATASET_NAME=online_shop
export BIGQUERY_TABLE_NAME=user_online_sessions
export BUCKET_NAME=$PROJECT_ID-bucket
export BUCKET_URL=gs://$BUCKET_NAME/user-online-sessions.csv
export DEFINITION_FILE=user-online-sessions-ref

gcloud services enable bigqueryconnection.googleapis.com datacatalog.googleapis.com

bq --location=$LOCATION mk $BIGQUERY_DATASET_NAME

bq mk --connection --location=$LOCATION --project_id=$PROJECT_ID \
    --connection_type=CLOUD_RESOURCE $CLOUD_CONNECTION_ID

bq show --connection $PROJECT_ID.$LOCATION.$CLOUD_CONNECTION_ID
export MEMBER=

gcloud projects add-iam-policy-binding $PROJECT_ID --member serviceAccount:$MEMBER  --role='roles/storage.objectViewer'

bq mkdef \
    --connection_id=$PROJECT_ID.$LOCATION.$CLOUD_CONNECTION_ID \
    --metadata_cache_mode=AUTOMATIC \
    --source_format=CSV --autodetect=true \
  $BUCKET_URL > $DEFINITION_FILE

bq mk --table \
    --external_table_definition=$DEFINITION_FILE \
    --max_staleness='0-0 0 4:0:0' \
    $PROJECT_ID:$BIGQUERY_DATASET_NAME.$BIGQUERY_TABLE_NAME 

gcloud projects remove-iam-policy-binding $PROJECT_ID --member user:$MEMBER  --role='roles/storage.objectViewer'


# https://cloud.google.com/bigquery/docs/column-level-security