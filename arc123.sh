export PROJECT_ID=
export REGION=
export ZONE=
export LOCATION=us

gcloud services enable bigqueryconnection.googleapis.com datacatalog.googleapis.com

export BIGQUERY_DATASET_NAME=ecommerce
export BIGQUERY_CONNECTION_NAME=customer_data_connection
export BIGQUERY_DEF_NAME=connection.txt
export BIGQUERY_SCHEMA_NAME=schema.json
export BIGQUERY_TABLE_NAME=customer_online_sessions
export BIGLAKE_TAG_TEMPLATE_NAME="Sensitive Data Template"
export BIGLAKE_TAG_TEMPLATE_FIELD_1_NAME="Has Sensitive Data"
export BIGLAKE_TAG_TEMPLATE_FIELD_2_NAME="Sensitive Data Type"
export BIGLAKE_TAG_TEMPLATE_ID=`echo "${BIGLAKE_TAG_TEMPLATE_NAME// /-}" | tr '[:upper:]' '[:lower:]'`
export BIGLAKE_TAG_TEMPLATE_FIELD_1_ID=`echo "${BIGLAKE_TAG_TEMPLATE_FIELD_1_NAME// /-}" | tr '[:upper:]' '[:lower:]'`
export BIGLAKE_TAG_TEMPLATE_FIELD_2_ID=`echo "${BIGLAKE_TAG_TEMPLATE_FIELD_2_NAME// /-}" | tr '[:upper:]' '[:lower:]'`

# Task 1
bq --location=$LOCATION mk $BIGQUERY_DATASET_NAME

# Task 2
cat > $BIGQUERY_SCHEMA_NAME <<EOF
[
  {
    "name": "customer_id",
    "type": "INTEGER",
    "mode": "REQUIRED"
  },
  {
    "name": "first_name",
    "type": "STRING",
    "mode": "REQUIRED"
  },
  {
    "name": "last_name",
    "type": "STRING",
    "mode": "REQUIRED"
  },
  {
    "name": "company",
    "type": "STRING",
    "mode": "NULLABLE"
  },
  {
    "name": "address",
    "type": "STRING",
    "mode": "NULLABLE"
  },
  {
    "name": "city",
    "type": "STRING",
    "mode": "NULLABLE"
  },
  {
    "name": "state",
    "type": "STRING",
    "mode": "NULLABLE"
  },
  {
    "name": "country",
    "type": "STRING",
    "mode": "NULLABLE"
  },
  {
    "name": "postal_code",
    "type": "STRING",
    "mode": "NULLABLE"
  },
  {
    "name": "phone",
    "type": "STRING",
    "mode": "NULLABLE"
  },
  {
    "name": "fax",
    "type": "STRING",
    "mode": "NULLABLE"
  },
  {
    "name": "email",
    "type": "STRING",
    "mode": "REQUIRED"
  },
  {
    "name": "support_rep_id",
    "type": "INTEGER",
    "mode": "NULLABLE"
  }
]
EOF

bq mk --connection \
    --location=$LOCATION \
    --project_id=$PROJECT_ID \
    --connection_type=CLOUD_RESOURCE \
    $BIGQUERY_CONNECTION_NAME

bq show --connection $PROJECT_ID.$LOCATION.$BIGQUERY_CONNECTION_NAME

export MEMBER=`bq show --format=json --connection $PROJECT_ID.$LOCATION.$BIGQUERY_CONNECTION_NAME | jq ".cloudResource.serviceAccountId"`
gcloud projects add-iam-policy-binding $PROJECT_ID --member serviceAccount:$MEMBER  --role='roles/storage.objectViewer'

bq mkdef \
    --connection_id=$BIGQUERY_CONNECTION_NAME \
    --source_format=csv \
    gs://$PROJECT_ID-bucket/customer-online-sessions.csv > $BIGQUERY_DEF_NAME

bq mk --table \
    --external_table_definition=$BIGQUERY_DEF_NAME \
    $PROJECT_ID:$BIGQUERY_DATASET_NAME.$BIGQUERY_TABLE_NAME \
    $BIGQUERY_SCHEMA_NAME

# Task 3
gcloud data-catalog tag-templates create $BIGLAKE_TAG_TEMPLATE_ID \
    --display-name="$BIGLAKE_TAG_TEMPLATE_NAME" \
    --location=$REGION \
    --field=id=$BIGLAKE_TAG_TEMPLATE_FIELD_1_ID,display-name="$BIGLAKE_TAG_TEMPLATE_FIELD_1_NAME",type=bool,required=TRUE \
    --field=id=$BIGLAKE_TAG_TEMPLATE_FIELD_2_ID,display-name="$BIGLAKE_TAG_TEMPLATE_FIELD_2_NAME",type='enum(Location Info|Contact Info)'

```
student_01_735b8d7c5dbb@cloudshell:~ (qwiklabs-gcp-00-99213dcb3802)$ gcloud data-catalog search "$BIGQUERY_TABLE_NAME" --include-project-ids=$PROJECT_ID
---
fullyQualifiedName: bigquery:qwiklabs-gcp-00-99213dcb3802.ecommerce.customer_online_sessions
integratedSystem: BIGQUERY
linkedResource: //bigquery.googleapis.com/projects/qwiklabs-gcp-00-99213dcb3802/datasets/ecommerce/tables/customer_online_sessions
modifyTime: '2024-07-10T06:50:13Z'
relativeResourceName: projects/qwiklabs-gcp-00-99213dcb3802/locations/us/entryGroups/@bigquery/entries/cHJvamVjdHMvcXdpa2xhYnMtZ2NwLTAwLTk5MjEzZGNiMzgwMi9kYXRhc2V0cy9lY29tbWVyY2UvdGFibGVzL2N1c3RvbWVyX29ubGluZV9zZXNzaW9ucw
searchResultSubtype: entry.table
searchResultType: ENTRY
```