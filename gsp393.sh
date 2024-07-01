export PROJECT_ID=
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')
export REGION=
export ZONE=
export IMAGE_REPO_NAME=cicd-challenge

gcloud config set compute/region $REGION

gcloud services enable \
    container.googleapis.com \
    clouddeploy.googleapis.com \
    artifactregistry.googleapis.com \
    cloudbuild.googleapis.com

# gcloud services enable \
#   cloudresourcemanager.googleapis.com \
#   container.googleapis.com \
#   artifactregistry.googleapis.com \
#   containerregistry.googleapis.com \
#   containerscanning.googleapis.com

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member=serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com \
    --role="roles/clouddeploy.jobRunner"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member=serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com \
    --role="roles/container.developer"

gcloud artifacts repositories create $IMAGE_REPO_NAME \
    --description="Image registry for tutorial web app" \
    --repository-format=docker \
    --location=$REGION

gcloud container clusters create cd-staging --node-locations= --num-nodes=1 --async
gcloud container clusters create cd-production --node-locations= --num-nodes=1 --async

cd ~/
git clone https://github.com/GoogleCloudPlatform/cloud-deploy-tutorials.git
cd cloud-deploy-tutorials
git checkout c3cae80 --quiet
cd tutorials/base

envsubst < clouddeploy-config/skaffold.yaml.template > web/skaffold.yaml
cat web/skaffold.yaml

cd web
skaffold build --interactive=false \
    --default-repo $REGION-docker.pkg.dev/$PROJECT_ID/$IMAGE_REPO_NAME \
    --file-output artifacts.json
cd ..

gcloud artifacts docker images list \
    $REGION-docker.pkg.dev/$PROJECT_ID/$IMAGE_REPO_NAME \
    --include-tags \
    --format yaml

cat web/artifacts.json | jq

gcloud config set deploy/region $REGION

gcloud config set deploy/region $REGION
cp clouddeploy-config/delivery-pipeline.yaml.template clouddeploy-config/delivery-pipeline.yaml
sed -i "s/targetId: staging/targetId: cd-staging/" clouddeploy-config/delivery-pipeline.yaml
sed -i "s/targetId: prod/targetId: cd-production/" clouddeploy-config/delivery-pipeline.yaml
sed -i "/targetId: test/d" clouddeploy-config/delivery-pipeline.yaml

gcloud beta deploy apply --file=clouddeploy-config/delivery-pipeline.yaml
gcloud beta deploy delivery-pipelines describe web-app

gcloud container clusters list --format="csv(name,status)"

CONTEXTS=("cd-staging" "cd-production")
for CONTEXT in ${CONTEXTS[@]}
do
    gcloud container clusters get-credentials ${CONTEXT} --region ${REGION}
    kubectl config rename-context gke_${PROJECT_ID}_${REGION}_${CONTEXT} ${CONTEXT}
done

for CONTEXT in ${CONTEXTS[@]}
do
    kubectl --context ${CONTEXT} apply -f kubernetes-config/web-app-namespace.yaml
done

# for CONTEXT in ${CONTEXTS[@]}
# do
#     envsubst < clouddeploy-config/target-$CONTEXT.yaml.template > clouddeploy-config/target-$CONTEXT.yaml
#     sed -i "s/$CONTEXT/cd-$CONTEXT/" clouddeploy-config/target-cd-$CONTEXT.yaml
#     gcloud beta deploy apply --file clouddeploy-config/target-$CONTEXT.yaml
# done
envsubst < clouddeploy-config/target-staging.yaml.template > clouddeploy-config/target-cd-staging.yaml
envsubst < clouddeploy-config/target-prod.yaml.template > clouddeploy-config/target-cd-production.yaml

sed -i "s/staging/cd-staging/" clouddeploy-config/target-cd-staging.yaml
sed -i "s/prod/cd-production/" clouddeploy-config/target-cd-production.yaml

for CONTEXT in ${CONTEXTS[@]}
do
    gcloud beta deploy apply --file clouddeploy-config/target-$CONTEXT.yaml
done

cat clouddeploy-config/target-test.yaml
cat clouddeploy-config/target-prod.yaml
gcloud beta deploy targets list

# Task 4
gcloud beta deploy releases create web-app-001 \
    --delivery-pipeline web-app \
    --build-artifacts web/artifacts.json \
    --source web/

gcloud beta deploy rollouts list \
    --delivery-pipeline web-app \
    --release web-app-001

kubectx cd-staging
kubectl get all -n web-app

# do promote
gcloud beta deploy releases promote \
    --delivery-pipeline web-app \
    --release web-app-001

# check rollout
gcloud beta deploy rollouts list \
    --delivery-pipeline web-app \
    --release web-app-001

# do aprove
gcloud beta deploy rollouts approve web-app-001-to-cd-production-000 \
    --delivery-pipeline web-app \
    --release web-app-001

gcloud beta deploy rollouts list \
    --delivery-pipeline web-app \
    --release web-app-001

kubectx cd-production
kubectl get all -n web-app

# Task 6

cd web
skaffold build --interactive=false \
    --default-repo $REGION-docker.pkg.dev/$PROJECT_ID/$IMAGE_REPO_NAME \
    --file-output artifacts.json

cd ..

gcloud beta deploy releases create web-app-002 \
    --delivery-pipeline web-app \
    --build-artifacts web/artifacts.json \
    --source web/

# Task 7
gcloud deploy targets rollback cd-staging \
   --delivery-pipeline=web-app \
   --quiet