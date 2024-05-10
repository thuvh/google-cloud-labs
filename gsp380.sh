export PROJECT_ID=qwiklabs-gcp-01-01f32539db04
export REGION=us-west3
export ZONE=us-west3-c
export ZONE_REP=us-west3-b
export BIGTABLE_INSTANCE_ID=ecommerce-recommendations
export STORAGE_TYPE=SSD
export BIGTABLE_CLUSTER_ID=ecommerce-recommendations-c1
export BIGTABLE_CLUSTER_REP_ID=ecommerce-recommendations-c2
export BIGTABLE_CLUSTER_MIN=1
export BIGTABLE_CLUSTER_MAX=5
export BIGTABLE_CLUSTER_CPU_UTILIZATION_TARGET=60
export DATAFLOW_JOB_NAME=import-sessions
export BIGTABLE_TABLE_NAME=SessionHistory
export DATAFLOW_JOB_NAME_2=import-recommendations
export BIGTABLE_TABLE_NAME_2=PersonalizedProducts
export BACKUP_ID=PersonalizedProducts_7
export BACKUP_TABLE=PersonalizedProducts
export BACKUP_EXPIRE=1w
export BACKUP_TABLE_NAME=PersonalizedProducts_7_restored

gcloud bigtable instances create $BIGTABLE_INSTANCE_ID \
    --display-name=$BIGTABLE_INSTANCE_ID \
    --cluster-storage-type=$STORAGE_TYPE \
    --cluster-config=id=$BIGTABLE_CLUSTER_ID,zone=$ZONE,autoscaling-min-nodes=$BIGTABLE_CLUSTER_MIN,autoscaling-max-nodes=$BIGTABLE_CLUSTER_MAX,autoscaling-cpu-target=$BIGTABLE_CLUSTER_CPU_UTILIZATION_TARGET


echo project = `gcloud config get-value project` \
    >> ~/.cbtrc
echo "instance = $BIGTABLE_INSTANCE_ID" >> ~/.cbtrc

cbt listinstances
cbt ls

gcloud storage buckets create gs://$PROJECT_ID --location=US

gcloud services list | grep dataflow
gcloud services disable dataflow.googleapis.com
gcloud services enable dataflow.googleapis.com

gcloud bigtable tables create $BIGTABLE_TABLE_NAME \
    --instance $BIGTABLE_INSTANCE_ID \
    --column-families="Engagements,Sales" \
    --splits "color,timestamp"

gcloud bigtable tables create $BIGTABLE_TABLE_NAME_2 \
    --instance $BIGTABLE_INSTANCE_ID \
    --column-families="Recommendations" 

gcloud dataflow jobs run $DATAFLOW_JOB_NAME \
    --gcs-location gs://dataflow-templates-$REGION/latest/GCS_SequenceFile_to_Cloud_Bigtable \
    --region $REGION \
    --parameters bigtableProject=$PROJECT_ID,bigtableInstanceId=$BIGTABLE_INSTANCE_ID,bigtableTableId=$BIGTABLE_TABLE_NAME,sourcePattern=gs://cloud-training/OCBL377/retail-engagements-sales-00000-of-00001 \
    --staging-location gs://$PROJECT_ID/temp

gcloud dataflow jobs run $DATAFLOW_JOB_NAME_2 \
    --gcs-location gs://dataflow-templates-$REGION/latest/GCS_SequenceFile_to_Cloud_Bigtable \
    --region $REGION \
    --parameters bigtableProject=$PROJECT_ID,bigtableInstanceId=$BIGTABLE_INSTANCE_ID,bigtableTableId=$BIGTABLE_TABLE_NAME_2,sourcePattern=gs://cloud-training/OCBL377/retail-recommendations-00000-of-00001 \
    --staging-location gs://$PROJECT_ID/temp2

cbt read $BIGTABLE_TABLE_NAME \
    count=10

gcloud bigtable clusters create $BIGTABLE_CLUSTER_REP_ID \
    --instance $BIGTABLE_INSTANCE_ID \
    --zone $ZONE_REP \
    --autoscaling-cpu-target $BIGTABLE_CLUSTER_CPU_UTILIZATION_TARGET \
    --autoscaling-max-nodes $BIGTABLE_CLUSTER_MAX \
    --autoscaling-min-nodes $BIGTABLE_CLUSTER_MIN

gcloud bigtable backups create $BACKUP_ID \
    --instance $BIGTABLE_INSTANCE_ID \
    --cluster $BIGTABLE_CLUSTER_ID \
    --table $BACKUP_TABLE \
    --retention-period $BACKUP_EXPIRE

gcloud bigtable tables restore \
    --source=projects/$PROJECT_ID/instances/$BIGTABLE_INSTANCE_ID/clusters/$BIGTABLE_CLUSTER_ID/backups/$BACKUP_ID \
    --destination=projects/$PROJECT_ID/instances/$BIGTABLE_INSTANCE_ID/tables/$BACKUP_TABLE_NAME


gcloud bigtable backups delete $BACKUP_ID --instance $BIGTABLE_INSTANCE_ID --cluster $BIGTABLE_CLUSTER_ID
gcloud bigtable tables delete $BACKUP_TABLE_NAME --instance $BIGTABLE_INSTANCE_ID
gcloud bigtable tables delete $BIGTABLE_TABLE_NAME --instance $BIGTABLE_INSTANCE_ID
gcloud bigtable tables delete $BIGTABLE_TABLE_NAME_2 --instance $BIGTABLE_INSTANCE_ID
gcloud bigtable clusters delete $BIGTABLE_CLUSTER_REP_ID --instance $BIGTABLE_INSTANCE_ID
gcloud bigtable clusters delete $BIGTABLE_CLUSTER_ID --instance $BIGTABLE_INSTANCE_ID
gcloud bigtable instances delete $BIGTABLE_INSTANCE_ID
