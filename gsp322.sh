export PROJECT_ID=
export SSH_IAP_NETWORK_TAG=
export HTTP_NETWORK_TAG=
export SSH_INTERNAL_NETWORK_TAG=
export REGION=
export ZONE=


gcloud compute firewall-rules delete open-access
gcloud compute networks list
gcloud compute networks subnets list --network acme-vpc
gcloud --format table compute instances list

gcloud compute instances resume bastion --zone $ZONE
gcloud compute networks subnets describe acme-mgmt-subnet

gcloud compute --project=$PROJECT_ID firewall-rules create $SSH_IAP_NETWORK_TAG \
    --direction=INGRESS \
    --priority=1000 \
    --network=acme-vpc \
    --action=ALLOW \
    --rules=tcp:22 \
    --source-ranges=35.235.240.0/20 \
    --target-tags=$SSH_IAP_NETWORK_TAG
gcloud compute instances add-tags bastion --tags=$SSH_IAP_NETWORK_TAG --zone=$ZONE

gcloud compute --project=$PROJECT_ID firewall-rules create $HTTP_NETWORK_TAG \
    --direction=INGRESS \
    --priority=1000 \
    --network=acme-vpc \
    --action=ALLOW \
    --rules=tcp:80 \
    --source-ranges=0.0.0.0/0 \
    --target-tags=$HTTP_NETWORK_TAG
gcloud compute instances add-tags juice-shop --tags=$HTTP_NETWORK_TAG --zone=$ZONE

gcloud compute --project=$PROJECT_ID firewall-rules create $SSH_INTERNAL_NETWORK_TAG \
    --direction=INGRESS \
    --priority=1000 \
    --network=acme-vpc \
    --action=ALLOW \
    --rules=tcp:22 \
    --source-ranges=192.168.10.0/24 \
    --target-tags=$SSH_INTERNAL_NETWORK_TAG
gcloud compute instances add-tags juice-shop --tags=$SSH_INTERNAL_NETWORK_TAG --zone=$ZONE

gcloud compute ssh bastion --zone=$ZONE
