export PROJECT_ID=$DEVSHELL_PROJECT_ID
export REGION=
export ZONE=

export GRIFFIN_DEV_VPC=griffin-dev-vpc
export GRIFFIN_DEV_SUBNET_WP=griffin-dev-wp
export GRIFFIN_DEV_SUBNET_MGMT=griffin-dev-mgmt
export GRIFFIN_PROD_VPC=griffin-prod-vpc
export GRIFFIN_PROD_SUBNET_WP=griffin-prod-wp
export GRIFFIN_PROD_SUBNET_MGMT=griffin-prod-mgmt
export GRIFFIN_K8S_CLUSTER=griffin-dev
export SSH_TAG=ssh

export GRIFFIN_SECOND_EMAIL=

# Task 1
gcloud compute networks create ${GRIFFIN_DEV_VPC} --subnet-mode=custom
gcloud compute networks subnets create ${GRIFFIN_DEV_SUBNET_WP} --network=${GRIFFIN_DEV_VPC} --range=192.168.16.0/20 --region=$REGION
gcloud compute networks subnets create ${GRIFFIN_DEV_SUBNET_MGMT} --network=${GRIFFIN_DEV_VPC} --range=192.168.32.0/20 --region=$REGION

# Task 2
gcloud compute networks create ${GRIFFIN_PROD_VPC} --subnet-mode=custom
gcloud compute networks subnets create ${GRIFFIN_PROD_SUBNET_WP} --network=${GRIFFIN_PROD_VPC} --range=192.168.48.0/20 --region=$REGION
gcloud compute networks subnets create ${GRIFFIN_PROD_SUBNET_MGMT} --network=${GRIFFIN_PROD_VPC} --range=192.168.64.0/20 --region=$REGION


# Task 3
gcloud compute firewall-rules create kraken-allow-ssh \
    --allow=tcp:22 \
    --direction=INGRESS \
    --source-tags=$SSH_TAG \
    --network=${GRIFFIN_DEV_VPC}

gcloud compute firewall-rules create kraken-allow-prod-ssh \
    --allow=tcp:22 \
    --direction=INGRESS \
    --source-tags=$SSH_TAG \
    --network=${GRIFFIN_PROD_VPC}

gcloud compute instances create kraken-bastion \
    --zone=$ZONE \
    --machine-type=e2-medium \
    --network-interface network=${GRIFFIN_DEV_VPC},subnet=${GRIFFIN_DEV_SUBNET_MGMT},stack-type=IPV4_ONLY \
    --network-interface network=${GRIFFIN_PROD_VPC},subnet=${GRIFFIN_PROD_SUBNET_MGMT},stack-type=IPV4_ONLY \
    --tags $SSH_TAG

# Task 4
gcloud sql instances create griffin-dev-db \
    --database-version=MYSQL_5_7 \
    --edition=enterprise \
    --zone=$ZONE \
    --root-password=20Qle4erWNSy \
    --cpu=2 \
    --memory=8GiB \
    --assign-ip

gcloud sql databases create wordpress \
    --instance=griffin-dev-db

gcloud sql users create wp_user \
    --host='%' \
    --instance=griffin-dev-db \
    --password=stormwind_rules

# Task 5
gcloud container clusters create ${GRIFFIN_K8S_CLUSTER} \
    --zone=$ZONE \
    --network=$GRIFFIN_DEV_VPC \
    --subnetwork=$GRIFFIN_DEV_SUBNET_WP \
    --num-nodes=2 \
    --machine-type=e2-standard-4

gcloud container clusters get-credentials $GRIFFIN_K8S_CLUSTER

# Task 6
gsutil cp -r gs://cloud-training/gsp321/wp-k8s .

cat > wp-k8s/wp-env.yaml <<EOF_END
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: wordpress-volumeclaim
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 200Gi
---
apiVersion: v1
kind: Secret
metadata:
  name: database
type: Opaque
stringData:
  username: wp_user
  password: stormwind_rules
EOF_END

cd wp-k8s
kubectl create -f wp-env.yaml

gcloud iam service-accounts keys create key.json \
    --iam-account=cloud-sql-proxy@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com
kubectl create secret generic cloudsql-instance-credentials \
    --from-file key.json

# TASK 7
export YOUR_SQL_INSTANCE=$(gcloud sql instances describe griffin-dev-db --format='value(connectionName)')
echo $YOUR_SQL_INSTANCE

kubectl create -f wp-deployment.yaml
kubectl create -f wp-service.yaml

# Task 8

export EXTERNAL_IP=$(kubectl get services wordpress -o=jsonpath='{.status.loadBalancer.ingress[0].ip}')

curl http://$EXTERNAL_IP


gcloud monitoring uptime create kraken-uptime-wp \
    --resource-type=uptime-url \
    --resource-labels=host=$EXTERNAL_IP,project_id=$PROJECT_ID

# Task 9
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="user:${GRIFFIN_SECOND_EMAIL}" \
    --role='roles/editor'
