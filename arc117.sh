export PROJECT_ID=qwiklabs-gcp-00-9a358e19a8af
export REGION=europe-west1

export LAKE_NAME="Customer Engagements"
export LAKE_ZONE_NAME="Raw Event Data"
export LAKE_ASSET_NAME="Raw Event Files"
export LAKE_TAG_TEMPLATE_NAME="Protected Raw Data Template"
export LAKE_TAG_TEMPLATE_FIELD_1_NAME="Protected Raw Data Flag"

export LAKE_ID=`echo "${LAKE_NAME// /-}" | tr '[:upper:]' '[:lower:]'`
export LAKE_ZONE_ID=`echo "${LAKE_ZONE_NAME// /-}" | tr '[:upper:]' '[:lower:]'`
export LAKE_ASSET_ID=`echo "${LAKE_ASSET_NAME// /-}" | tr '[:upper:]' '[:lower:]'`
export LAKE_TAG_TEMPLATE_ID=`echo "${LAKE_TAG_TEMPLATE_NAME// /_}" | tr '[:upper:]' '[:lower:]'`
export LAKE_TAG_TEMPLATE_FIELD_1_ID=`echo "${LAKE_TAG_TEMPLATE_FIELD_1_NAME// /_}" | tr '[:upper:]' '[:lower:]'`

gcloud services enable \
  dataplex.googleapis.com \
  datacatalog.googleapis.com

gcloud dataplex lakes create $LAKE_ID \
   --location=$REGION \
   --display-name="$LAKE_NAME" \
   --description="$LAKE_NAME"

gcloud dataplex zones create $LAKE_ZONE_ID \
    --location=$REGION \
    --lake=$LAKE_ID \
    --display-name="$LAKE_ZONE_NAME" \
    --resource-location-type=SINGLE_REGION \
    --type=RAW \
    --discovery-enabled \
    --discovery-schedule="0 * * * *"

gsutil mb -l $REGION gs://$DEVSHELL_PROJECT_ID

gcloud dataplex assets create $LAKE_ASSET_ID \
    --location=$REGION \
    --lake=$LAKE_ID \
    --zone=$LAKE_ZONE_ID \
    --display-name="$LAKE_ASSET_NAME" \
    --resource-type=STORAGE_BUCKET \
    --resource-name=projects/$DEVSHELL_PROJECT_ID/buckets/$DEVSHELL_PROJECT_ID \
    --discovery-enabled \
    --discovery-schedule="0 * * * *"

gcloud data-catalog tag-templates create $LAKE_TAG_TEMPLATE_ID \
    --display-name="$LAKE_TAG_TEMPLATE_NAME" \
    --location=$REGION \
    --field=id=$LAKE_TAG_TEMPLATE_FIELD_1_ID,display-name="$LAKE_TAG_TEMPLATE_FIELD_1_NAME",type='enum(Y|N),required=TRUE'

gcloud data-catalog entry-groups list --location=$REGION
gcloud data-catalog entries list --location=$REGION
