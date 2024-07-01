export PROJECT_ID=
export REGION=
# export ZONE=

gcloud service enable run.googleapis.com
gcloud config set run/region $REGION

gcloud firestore databases create --location=nam5
gcloud firestore databases create --location=$REGION

git clone https://github.com/rosera/pet-theory.git
cd pet-theory/lab06/firebase-import-csv/solution

npm install
node index.js netflix_titles_original.csv

cd ~/pet-theory/lab06/firebase-rest-api/solution-01
gcloud builds submit --tag gcr.io/$GOOGLE_CLOUD_PROJECT/rest-api:0.1
gcloud run deploy netflix-dataset-service --image gcr.io/$GOOGLE_CLOUD_PROJECT/rest-api:0.1 --allow-unauthenticated

SERVICE_URL=https://netflix-dataset-service-pbowrneawa-uw.a.run.app
curl -X GET $SERVICE_URL

cd ~/pet-theory/lab06/firebase-rest-api/solution-02
gcloud builds submit --tag gcr.io/$GOOGLE_CLOUD_PROJECT/rest-api:0.2
gcloud run deploy netflix-dataset-service --image gcr.io/$GOOGLE_CLOUD_PROJECT/rest-api:0.2 --allow-unauthenticated

SERVICE_URL=https://netflix-dataset-service-pbowrneawa-uw.a.run.app
curl -X GET $SERVICE_URL/2019

cd pet-theory/lab06/firebase-frontend/public

nano app.js # comment line 3 and uncomment line 4, insert your netflix-dataset-service url
npm install

# REST_API_SERVICE=$SERVICE_URL/2019

cd ~/pet-theory/lab06/firebase-frontend
gcloud builds submit --tag gcr.io/$GOOGLE_CLOUD_PROJECT/frontend-staging:0.1
gcloud run deploy frontend-staging-service --image gcr.io/$GOOGLE_CLOUD_PROJECT/frontend-staging:0.1

gcloud builds submit --tag gcr.io/$GOOGLE_CLOUD_PROJECT/frontend-production:0.1
gcloud run deploy frontend-production-service --image gcr.io/$GOOGLE_CLOUD_PROJECT/frontend-production:0.1
