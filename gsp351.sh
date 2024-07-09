export PROJECT_ID=$DEVSHELL_PROJECT_ID
export REGION=
export ZONE=

export MYSQL_SOURCE_COMPUTE_INSTANCE=
export CLOUD_SQL_INSTANCE_ONE_TIME=
export CLOUD_SQL_INSTANCE_CONTINUOUS_TIME=

gcloud config set compute/zone $ZONE
gcloud config set compute/region $REGION

gcloud services enable datamigration.googleapis.com
gcloud services enable servicenetworking.googleapis.com

gcloud compute instances describe $MYSQL_SOURCE_COMPUTE_INSTANCE`
export MYSQL_SOURCE_COMPUTE_INSTANCE_EXTERNAL_IP=`gcloud compute instances describe $MYSQL_SOURCE_COMPUTE_INSTANCE --format="value()"`

gcloud sql instances list

gcloud database-migration connection-profiles create mysql ${MYSQL_SOURCE_COMPUTE_INSTANCE} \
    --region=$REGION \
    --password=changeme \
    --username=admin \
    --host=${MYSQL_SOURCE_COMPUTE_INSTANCE_EXTERNAL_IP} \
    --port=3306

# https://cloud.google.com/sql/docs/mysql/instance-settings
gcloud database-migration connection-profiles create cloudsql ${CLOUD_SQL_INSTANCE_ONE_TIME} \
    --region=$REGION \
    --edition=enterprise \
    --database-version=MYSQL_8_0 \
    --tier=db-custom-2-7680 \
    --source-id=${CLOUD_SQL_INSTANCE_ONE_TIME} \
    --tier=db-n1-standard-1 \
    --data-disk-type=PD_SSD \
    --data-disk-size=10 \
    --root-password=supersecret!


gcloud database-migration migration-jobs create ${CLOUD_SQL_INSTANCE_ONE_TIME} \
    --region=$REGION \
    --type=ONE_TIME \
    --source=$MYSQL_SOURCE_COMPUTE_INSTANCE \
    --destination=${CLOUD_SQL_INSTANCE_ONE_TIME} \
    --vm=vm1 \
    --vm-ip=1.1.1.1 \
    --vm-port=1111 \
    --vpc=projects/my-project/global/networks/my-network

gcloud database-migration migration-jobs create my-migration-job \
    --region=us-central1 \
    --type=CONTINUOUS \
    --source=cp1 \
    --destination=cp2 \
    --peer-vpc=projects/my-project/global/networks/my-network