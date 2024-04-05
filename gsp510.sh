#!/bin/bash 

export REGION=us-east4
export ZONE=us-east4-a
export PROJECT_ID=qwiklabs-gcp-03-c88c0e02a8ba
export K8S_CLUSTER_NAME=hello-world-e5as
export K8S_NAMESPACE_NAME=gmp-anpd
export REPOSITORY_NAME=sandbox-repo
export IMAGE_TAG=v2
export K8S_SERVICE_NAME=helloweb-service-fw3g
export K8S_SERVICE_PORT=8080
export K8S_TARGET_PORT=8080

gcloud container clusters create $K8S_CLUSTER_NAME \
  --cluster-version=1.27.8-gke.1067004 \
  --release-channel=regular \
  --enable-autoscaling \
  --num-nodes=3 \
  --min-nodes=2 \
  --max-nodes=6 \
  --zone=$ZONE

gcloud container clusters get-credentials $K8S_CLUSTER_NAME --zone=$ZONE

gcloud container clusters update $K8S_CLUSTER_NAME --enable-managed-prometheus --zone $ZONE 

kubectl create ns $K8S_NAMESPACE_NAME

kubectl config set-context --current --namespace=$K8S_NAMESPACE_NAME

gsutil cp gs://spls/gsp510/prometheus-app.yaml .
gsutil cp gs://spls/gsp510/pod-monitoring.yaml .
gsutil cp -r gs://spls/gsp510/hello-app/ .

kubectl apply -f prometheus-app.yaml 
kubectl apply -f pod-monitoring.yaml

gcloud artifacts repositories create $REPOSITORY_NAME \
    --repository-format=docker \
    --location=$REGION \
    --immutable-tags \
    --async

kubectl apply -f ~/hello-app/manifests/helloweb-deployment.yaml

gcloud auth configure-docker $REGION-docker.pkg.dev --quiet
export IMAGE_URL=$REGION-docker.pkg.dev/$PROJECT_ID/$REPOSITORY_NAME/hello-app:$IMAGE_TAG

# gcloud builds submit -t $REGION-docker.pkg.dev/qwiklabs-gcp-00-a95b4dbe4583/sandbox-repo/hello-app:$IMAGE_TAG
docker build -t $IMAGE_URL ~/hello-app
docker push $IMAGE_URL

kubectl set image deployment/helloweb hello-app=$IMAGE_URL
kubectl expose deployment helloweb --name=$K8S_SERVICE_NAME --type=LoadBalancer --port $K8S_SERVICE_PORT --target-port $K8S_TARGET_PORT