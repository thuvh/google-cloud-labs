export PROJECT_ID=$DEVSHELL_PROJECT_ID
export REGION=
export ZONE=

export K8S_CLUSTER_NAME=

export MONOLITH_IMAGE_NAME=
export MONOLITH_IMAGE_TAG=1.0.0
export MONOLITH_CONTAINER_NAME=
export ORDER_IMAGE_NAME=
export ORDER_IMAGE_TAG=1.0.0
export ORDER_CONTAINER_NAME=
export PRODUCT_IMAGE_NAME=
export PRODUCT_IMAGE_TAG=1.0.0
export PRODUCT_CONTAINER_NAME=
export UI_IMAGE_NAME=
export UI_IMAGE_TAG=1.0.0
export UI_CONTAINER_NAME=

gcloud config set compute/zone $ZONE
gcloud config set compute/region $REGION

gcloud services enable \
    cloudbuild.googleapis.com \
    container.googleapis.com

# Task 1
git clone https://github.com/googlecodelabs/monolith-to-microservices.git

cd ~/monolith-to-microservices

./setup.sh

nvm install --lts

cd ~/monotlith-to-microservices/monolith
gcloud builds submit --tag gcr.io/${GOOGLE_CLOUD_PROJECT}/${MONOLITH_IMAGE_NAME}:${MONOLITH_IMAGE_TAG} .

# Task 2
gcloud container clusters create $K8S_CLUSTER_NAME \
    --num-nodes 3 \
    --zone $ZONE \
    --machine-type=e2-medium

gcloud container clusters get-credentials $K8S_CLUSTER_NAME --zone=$ZONE

kubectl create deployment $MONOLITH_CONTAINER_NAME \
    --image=gcr.io/${GOOGLE_CLOUD_PROJECT}/${MONOLITH_IMAGE_NAME}:${MONOLITH_IMAGE_TAG}
kubectl expose deployment $MONOLITH_CONTAINER_NAME --type=LoadBalancer --port 80 --target-port 8080

# Task 3
cd ~/monolith-to-microservices/microservices/src/orders
gcloud builds submit --tag gcr.io/${GOOGLE_CLOUD_PROJECT}/${ORDER_IMAGE_NAME}:${ORDER_IMAGE_TAG} .

cd ~/monolith-to-microservices/microservices/src/products
gcloud builds submit --tag gcr.io/${GOOGLE_CLOUD_PROJECT}/${PRODUCT_IMAGE_NAME}:${PRODUCT_IMAGE_TAG} .

kubectl create deployment $ORDER_CONTAINER_NAME \
    --image=gcr.io/${GOOGLE_CLOUD_PROJECT}/${ORDER_IMAGE_NAME}:${ORDER_IMAGE_TAG}
kubectl expose deployment $ORDER_CONTAINER_NAME --type=LoadBalancer --port 80 --target-port 8081

kubectl create deployment $PRODUCT_CONTAINER_NAME \
    --image=gcr.io/${GOOGLE_CLOUD_PROJECT}/${PRODUCT_IMAGE_NAME}:${PRODUCT_IMAGE_TAG}
kubectl expose deployment $PRODUCT_CONTAINER_NAME --type=LoadBalancer --port 80 --target-port 8082

# Task 5
cd ~/monolith-to-microservices/microservices/src/frontend
nano .env
# REACT_APP_ORDERS_URL=http://<ORDERS_IP_ADDRESS>/api/orders
# REACT_APP_PRODUCTS_URL=http://<PRODUCTS_IP_ADDRESS>/api/products

# npm run build
# npm run build:monolith
cd ~/monolith-to-microservices/microservices/src/frontend
gcloud builds submit --tag gcr.io/${GOOGLE_CLOUD_PROJECT}/${UI_IMAGE_NAME}:${UI_IMAGE_TAG} .

gcloud builds submit --tag gcr.io/${GOOGLE_CLOUD_PROJECT}/monolith:2.0.0 .
kubectl expose deployment ${UI_CONTAINER_NAME} --type=LoadBalancer --port 80 --target-port 8080
