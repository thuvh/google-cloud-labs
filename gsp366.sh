

export PROJECT_ID=
export INSTANCE_NAME= 
export ZONE=
export DOCKER_CONTAINER_NAME=


gcloud compute instances list
gcloud compute ssh ${INSTANCE_NAME} --zone $ZONE

export DOCKER_TAG=gcr.io/ql-shared-resources-test/defect_solution@sha256:776fd8c65304ac017f5b9a986a1b8189695b7abbff6aa0e4ef693c46c7122f4c
export VISERVING_CPU_DOCKER_WITH_MODEL=${DOCKER_TAG}
export HTTP_PORT=8602
export LOCAL_METRIC_PORT=8603

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

export DEFECTIVE_IMG_NAME=IMG_0769.png
export DEFECTIVE_RESULT_FILE=

export NON_DEFECTIVE_IMG_NAME=IMG_07703.png
export NON_DEFECTIVE_RESULT_FILE=

declare -A steps=( [${DEFECTIVE_IMAGE_NAME}]=${DEFECTIVE_RESULT_FILE} [${NON_DEFECTIVE_IMG_NAME}]=${NON_DEFECTIVE_RESULT_FILE} )

for idx in "${!steps[@]}"; do
    img_name=$idx
    result_name=${steps[$i]}
    echo "$img_name -> ${result_name}"
    # gsutil cp gs://${PROJECT_ID}/cosmetic-test-data/${img_name} .
    # python3 ./prediction_script.py --input_image_file=./${img_name}  --port=${HTTP_PORT} --num_of_requests=10 --output_result_file=${result_name}
done



