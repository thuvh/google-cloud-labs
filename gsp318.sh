
source <(gsutil cat gs://cloud-training/gsp318/marking/setup_marking_v2.sh)

gcloud source repos clone valkyrie-app

touch valkyrie-app/Dockerfile

cat 

FROM golang:1.10
WORKDIR /go/src/app
COPY source .
RUN go install -v
ENTRYPOINT ["app","-single=true","-port=8080"]

EOF

export IMAGE_NAME=valkyrie-prod
export IMAGE_TAG=v0.0.3

export IMAGE_FULL_NAME=$IMAGE_NAME:$IMAGE_TAG
docker build -t $IMAGE_FULL_NAME .

bash ~/marking/step1_v2.sh

docker run -p 8080:8080 $IMAGE_FULL_NAME

bash ~/marking/step2_v2.sh

export REPOSITORY_NAME=valkyrie-repository
export REGION=us-central1

gcloud artifacts repositories create $REPOSITORY_NAME \
	--repository-format=docker \
	--location=$REGION \
	--immutable-tags \
	--async

export PROJECT_ID=qwiklabs-gcp-02-39056799f03f

docker tag $IMAGE_FULL_NAME $REGION-docker.pkg.dev/$PROJECT_ID/$REPOSITORY_NAME/$IMAGE_FULL_NAME

gcloud container  clusters list 
gcloud container  clusters get-credentials valkyrie-dev --zone us-central1-c 
kubectl get nodes
kubectl create -f k8s/deployment.yaml 
kubectl create -f k8s/service.yaml 

