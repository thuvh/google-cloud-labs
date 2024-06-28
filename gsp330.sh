export PROJECT_ID=$DEVSHELL_PROJECT_ID
export REGION=
export ZONE=
export EMAIL=
export NAME="Student $EMAIL"
export DOCKER_REPOSITORY_NAME=my-repository
export REPOSITORY_NAME=sample-app
export K8S_CLUSTER_NAME=hello-cluster

gcloud services enable container.googleapis.com \
    cloudbuild.googleapis.com \
    sourcerepo.googleapis.com \
    containeranalysis.googleapis.com

gcloud projects add-iam-policy-binding $PROJECT_ID \
--member=serviceAccount:$(gcloud projects describe $PROJECT_ID \
--format="value(projectNumber)")@cloudbuild.gserviceaccount.com --role="roles/container.developer"

git config --global user.email $EMAIL
git config --global user.name $NAME

gcloud services enable container.googleapis.com \
    cloudbuild.googleapis.com \
    sourcerepo.googleapis.com

gcloud artifacts repositories create $DOCKER_REPOSITORY_NAME \
    --repository-format=docker \
    --location=$REGION \
    --description="Docker repository" \
    --project=$DEVSHELL_PROJECT_ID

gcloud container clusters create $K8S_CLUSTER_NAME \
    --zone $ZONE \
    --cluster-version=latest \
    --release-channel=regular \
    --enable-autoscaling \
    --num-nodes=3 \
    --min-nodes=2 \
    --max-nodes=6

gcloud container clusters get-credentials $K8S_CLUSTER_NAME --zone $ZONE

kubectl create ns prod
kubectl create ns dev

gcloud source repos create $REPOSITORY_NAME
git clone https://source.developers.google.com/p/$DEVSHELL_PROJECT_ID/r/$REPOSITORY_NAME
cd ~
gsutil cp -r gs://spls/gsp330/sample-app/* sample-app
for file in sample-app/cloudbuild-dev.yaml sample-app/cloudbuild.yaml; do
    sed -i "s/<your-region>/${REGION}/g" "$file"
    sed -i "s/<your-zone>/${ZONE}/g" "$file"
done

cd sample-app
git add --all .
git commit -m "init"
git push -u origin master
git checkout -b dev
git push -u origin dev

export PROJECT_NUMBER=`gcloud projects describe $PROJECT_ID --format="value(projectNumber)"`

gcloud builds triggers create cloud-source-repositories \
    --name sample-app-prod-deploy \
    --repo=$REPOSITORY_NAME \
    --branch-pattern="^master$" \
    --build-config=cloudbuild.yaml \
    --service-account="$PROJECT_NUMBER-compute@developer.gserviceaccount.com"

gcloud builds triggers create cloud-source-repositories \
    --name sample-app-dev-deploy \
    --repo=$REPOSITORY_NAME \
    --branch-pattern="^dev$" \
    --build-config=cloudbuild-dev.yaml


steps:
  # Step 1: Compile the Go Application
  - name: 'gcr.io/cloud-builders/go'
    env: ['GOPATH=/gopath']
    args: ['build', '-o', 'main', 'main.go']

  # Step 2: Build the Docker image for the Go application
  - name: 'gcr.io/cloud-builders/docker'
    args: ['build', '-t', 'europe-west4-docker.pkg.dev/$PROJECT_ID/my-repository/hello-cloudbuild-dev:<version>', '.']

  # Step 3: Push the Docker image to Artifact Registry
  - name: 'gcr.io/cloud-builders/docker'
    args: ['push', 'europe-west4-docker.pkg.dev/$PROJECT_ID/my-repository/hello-cloudbuild-dev:<version>']

  # Step 4: Apply the production deployment YAML file to the production namespace
  - name: 'gcr.io/cloud-builders/kubectl'
    id: 'Deploy'
    args: ['-n', 'dev', 'apply', '-f', 'dev/deployment.yaml']
    env:
    - 'CLOUDSDK_COMPUTE_REGION=europe-west4-a'
    - 'CLOUDSDK_CONTAINER_CLUSTER=hello-cluster'
options:
  logging: CLOUD_LOGGING_ONLY

kubectl expose deployment development-deployment \
    --name dev-deployment-service \
    --type LoadBalancer \
    --port 8080 \
    --target-port 8080 \
    -n dev

#Task 6
gcloud builds list