export PROJECT_ID=$DEVSHELL_PROJECT_ID
export REGION=
export ZONE=
export CUSTOM_SECURITY_ZONE_NAME=
export SERVICE_ACCOUNT_NAME=
export K8S_CLUSTER_NAME=

# Task 1
gcloud iam roles create $CUSTOM_SECURITY_ZONE_NAME \
    --project $DEVSHELL_PROJECT_ID \
    --title $CUSTOM_SECURITY_ZONE_NAME \
    --description "Custom role description." \
    --permissions storage.buckets.get,storage.objects.get,storage.objects.list,storage.objects.update,storage.objects.create \
    --stage ALPHA

# Task 2
gcloud iam service-accounts create $SERVICE_ACCOUNT_NAME --display-name "Orca Private Cluster Service Account"

# Task 3
gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID --member serviceAccount:$SERVICE_ACCOUNT_NAME@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com --role roles/monitoring.viewer
gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID --member serviceAccount:$SERVICE_ACCOUNT_NAME@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com --role roles/monitoring.metricWriter
gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID --member serviceAccount:$SERVICE_ACCOUNT_NAME@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com --role roles/logging.logWriter
gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID --member serviceAccount:$SERVICE_ACCOUNT_NAME@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com --role projects/$DEVSHELL_PROJECT_ID/roles/$CUSTOM_SECURITY_ZONE_NAME

# Task 4
gcloud compute networks subnets list --project $DEVSHELL_PROJECT_ID
gcloud compute networks subnets describe orca-build-subnet --region=$REGION --project=$DEVSHELL_PROJECT_ID
export K8S_NETWORK=`gcloud --format "value(ipCidrRange)" compute networks subnets describe orca-build-subnet --region=$REGION --project=$DEVSHELL_PROJECT_ID`

gcloud compute instances describe orca-jumphost --zone=$ZONE | grep natIP
gcloud --format="value(networkInterfaces[0].accessConfigs[0].natIP)" compute instances describe orca-jumphost --zone=$ZONE

export K8S_MASTER_IP=`gcloud --format="value(networkInterfaces[0].networkIP)" compute instances describe orca-jumphost --zone=$ZONE`

gcloud container clusters create $K8S_CLUSTER_NAME \
    --num-nodes 1 \
    --master-ipv4-cidr 172.16.0.16/28 \
    --network orca-build-vpc \
    --subnetwork orca-build-subnet \
    --enable-master-authorized-networks \
    --master-authorized-networks "$K8S_MASTER_IP/32" \
    --enable-ip-alias \
    --enable-private-nodes \
    --enable-private-endpoint \
    --service-account $SERVICE_ACCOUNT_NAME@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com \
    --zone=$ZONE

# Task 5
echo "gcloud container clusters get-credentials $K8S_CLUSTER_NAME --internal-ip --project=$DEVSHELL_PROJECT_ID --zone=$ZONE"

gcloud compute ssh orca-jumphost --zone $ZONE --project "$DEVSHELL_PROJECT_ID"

sudo apt-get install google-cloud-sdk-gke-gcloud-auth-plugin
echo "export USE_GKE_GCLOUD_AUTH_PLUGIN=True" >> ~/.bashrc
source ~/.bashrc
gcloud container clusters get-credentials $K8S_CLUSTER_NAME --internal-ip --project=$DEVSHELL_PROJECT_ID --zone=$ZONE

kubectl create deployment hello-server --image=gcr.io/google-samples/hello-app:1.0
