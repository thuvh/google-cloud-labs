
export PROJECT_ID=qwiklabs-gcp-03-32b27fef117b
export INSTANCE_NAME=lab-vm
export ZONE=us-east4-a
export DOCKER_CONTAINER_NAME=product_inspection


gcloud compute instances list
gcloud compute ssh ${INSTANCE_NAME} --zone $ZONE

export PROJECT_ID=qwiklabs-gcp-03-32b27fef117b
export INSTANCE_NAME=lab-vm
export ZONE=us-east4-a
export DOCKER_CONTAINER_NAME=product_inspection

export DOCKER_TAG=gcr.io/ql-shared-resources-test/defect_solution@sha256:776fd8c65304ac017f5b9a986a1b8189695b7abbff6aa0e4ef693c46c7122f4c
export VISERVING_CPU_DOCKER_WITH_MODEL=${DOCKER_TAG}
export HTTP_PORT=9000
export LOCAL_METRIC_PORT=3006

docker run -v /secrets:/secrets --rm -d --name $DOCKER_CONTAINER_NAME \
    --network="host" \
    -p ${HTTP_PORT}:8602 \
    -p ${LOCAL_METRIC_PORT}:8603 \
    -t ${VISERVING_CPU_DOCKER_WITH_MODEL} \
    --metric_project_id="${PROJECT_ID}" \
    --use_default_credentials=false \
    --service_account_credentials_json=/secrets/assembly-usage-reporter.json

docker container ls

gsutil cp gs://cloud-training/gsp895/prediction_script.py .

gsutil mb gs://${PROJECT_ID}
gsutil -m cp gs://cloud-training/gsp897/cosmetic-test-data/*.png \
gs://${PROJECT_ID}/cosmetic-test-data/

export DEFECTIVE_IMG_NAME=IMG_07703.png
export DEFECTIVE_RESULT_FILE=$HOME/defective_product_result.json

export NON_DEFECTIVE_IMG_NAME=IMG_0769.png
export NON_DEFECTIVE_RESULT_FILE=$HOME/non_defective_product_result.json

IMG_NAMES=( ${DEFECTIVE_IMG_NAME} ${NON_DEFECTIVE_IMG_NAME} )
RESULT_NAMES=( ${DEFECTIVE_RESULT_FILE} ${NON_DEFECTIVE_RESULT_FILE} )
for idx in "${!IMG_NAMES[@]}"; do
  img_name=${IMG_NAMES[$idx]}
  result_name=${RESULT_NAMES[$idx]}
  echo "$img_name -> ${result_name}"
  if [ -f ${result_name} ]; then
    rm ${result_name}
  fi
  gsutil cp gs://${PROJECT_ID}/cosmetic-test-data/${img_name} .
  python3 ./prediction_script.py --input_image_file=./${img_name}  --port=8602 --output_result_file=${result_name}
done
