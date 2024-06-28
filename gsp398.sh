
export PROJECT_ID=$DEVSHELL_PROJECT_ID
export REGION=us-east4
export ZONE=us-east4-c
export VM_IMAGE_PROJECT=deeplearning-platform-release
export VM_IMAGE_NAME=tf-ent-2-11-cpu-v20240613
export MACHINE_TYPE=e2-standard-4

gcloud services enable \
  compute.googleapis.com \
  monitoring.googleapis.com \
  logging.googleapis.com \
  notebooks.googleapis.com \
  aiplatform.googleapis.com \
  artifactregistry.googleapis.com \
  container.googleapis.com

gcloud workbench instances create cnn-challenge \
    --project=$DEVSHELL_PROJECT_ID \
    --location=$ZONE \
    --vm-image-project=$VM_IMAGE_PROJECT \
    --vm-image-name=$VM_IMAGE_NAME \
    --machine-type=$MACHINE_TYPE
    #--metadata=METADATA

git clone https://github.com/GoogleCloudPlatform/training-data-analyst
