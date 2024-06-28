export PROJECT_ID=
export REGION=
export ZONE=

export SPANNER_INSTANCE_NAME=banking-ops-instance
export SPANNER_DB_NAME=banking-ops-db
export SPANNER_CUSTOMER_DATA_GS_URI=gs://cloud-training/OCBL375/Customer_List_500.csv
export DATAFLOW_JOB_NAME=spanner-load

gcloud services enable spanner.googleapis.com
gcloud services disable dataflow.googleapis.com --force
gcloud services enable dataflow.googleapis.com

gcloud spanner instances create $SPANNER_INSTANCE_NAME \
--config=regional-$REGION  \
--description="Sample Instance" \
--nodes=1

gcloud spanner databases create $SPANNER_DB_NAME \
--instance=$SPANNER_INSTANCE_NAME

gcloud spanner databases ddl update $SPANNER_DB_NAME --instance=$SPANNER_INSTANCE_NAME --ddl='CREATE TABLE Portfolio (PortfolioId INT64 NOT NULL, Name STRING(MAX), ShortName STRING(MAX), PortfolioInfo STRING(MAX)) PRIMARY KEY (PortfolioId)'
gcloud spanner databases ddl update $SPANNER_DB_NAME --instance=$SPANNER_INSTANCE_NAME --ddl='CREATE TABLE Category (CategoryId INT64 NOT NULL, PortfolioId INT64 NOT NULL, CategoryName STRING(MAX), PortfolioInfo STRING(MAX)) PRIMARY KEY (CategoryId)'
gcloud spanner databases ddl update $SPANNER_DB_NAME --instance=$SPANNER_INSTANCE_NAME --ddl='CREATE TABLE Product (ProductId INT64 NOT NULL, CategoryId INT64 NOT NULL, PortfolioId INT64 NOT NULL, ProductName STRING(MAX), ProductAssetCode STRING(25), ProductClass STRING(25)) PRIMARY KEY (ProductId)'
gcloud spanner databases ddl update $SPANNER_DB_NAME --instance=$SPANNER_INSTANCE_NAME --ddl='CREATE TABLE Customer (CustomerId STRING(36) NOT NULL, Name STRING(MAX) NOT NULL, Location STRING(MAX) NOT NULL) PRIMARY KEY (CustomerId)'


gcloud spanner rows insert \
    --table=Portfolio \
    --database=$SPANNER_DB_NAME \
    --instance=$SPANNER_INSTANCE_NAME \
    --data=PortfolioId=1,Name=Banking,ShortName=Bnkg,PortfolioInfo="All Banking Busines"

gcloud spanner rows insert \
    --table=Portfolio \
    --database=$SPANNER_DB_NAME \
    --instance=$SPANNER_INSTANCE_NAME \
    --data=PortfolioId=2,Name="Asset Growth",ShortName=AsstGrwth,PortfolioInfo="All Asset Focused Products"

gcloud spanner rows insert \
    --table=Portfolio \
    --database=$SPANNER_DB_NAME \
    --instance=$SPANNER_INSTANCE_NAME \
    --data=PortfolioId=3,Name="Insurance",ShortName=Insurance,PortfolioInfo="All Insurance Focused Products"

gcloud spanner rows insert \
    --table=Category \
    --database=$SPANNER_DB_NAME \
    --instance=$SPANNER_INSTANCE_NAME \
    --data=CategoryId=1,PortfolioId=1,CategoryName="Cash"

gcloud spanner rows insert \
    --table=Category \
    --database=$SPANNER_DB_NAME \
    --instance=$SPANNER_INSTANCE_NAME \
    --data=CategoryId=2,PortfolioId=2,CategoryName="Investments - Short Return"

gcloud spanner rows insert \
    --table=Category \
    --database=$SPANNER_DB_NAME \
    --instance=$SPANNER_INSTANCE_NAME \
    --data=CategoryId=3,PortfolioId=2,CategoryName="Annuities"

gcloud spanner rows insert \
    --table=Category \
    --database=$SPANNER_DB_NAME \
    --instance=$SPANNER_INSTANCE_NAME \
    --data=CategoryId=4,PortfolioId=3,CategoryName="Life Insurance"

# Product
gcloud spanner rows insert \
    --table=Product \
    --database=$SPANNER_DB_NAME \
    --instance=$SPANNER_INSTANCE_NAME \
    --data=ProductId=1,CategoryId=1,PortfolioId=1,ProductName="Checking Account",ProductAssetCode=ChkAcct,ProductClass="Banking LOB"

gcloud spanner rows insert \
    --table=Product \
    --database=$SPANNER_DB_NAME \
    --instance=$SPANNER_INSTANCE_NAME \
    --data=ProductId=2,CategoryId=2,PortfolioId=2,ProductName="Mutual Fund Consumer Goods",ProductAssetCode=MFundCG,ProductClass="Investment LOB"

gcloud spanner rows insert \
    --table=Product \
    --database=$SPANNER_DB_NAME \
    --instance=$SPANNER_INSTANCE_NAME \
    --data=ProductId=3,CategoryId=3,PortfolioId=2,ProductName="Annuity Early Retirement",ProductAssetCode=AnnuFixed,ProductClass="Investment LOB"

gcloud spanner rows insert \
    --table=Product \
    --database=$SPANNER_DB_NAME \
    --instance=$SPANNER_INSTANCE_NAME \
    --data=ProductId=4,CategoryId=4,PortfolioId=3,ProductName="Term Life Insurance",ProductAssetCode=TermLife,ProductClass="Insurance LOB"

gcloud spanner rows insert \
    --table=Product \
    --database=$SPANNER_DB_NAME \
    --instance=$SPANNER_INSTANCE_NAME \
    --data=ProductId=5,CategoryId=1,PortfolioId=1,ProductName="Savings Account",ProductAssetCode=SavAcct,ProductClass="Banking LOB"

gcloud spanner rows insert \
    --table=Product \
    --database=$SPANNER_DB_NAME \
    --instance=$SPANNER_INSTANCE_NAME \
    --data=ProductId=6,CategoryId=1,PortfolioId=1,ProductName="Personal Loan",ProductAssetCode=PersLn,ProductClass="Banking LOB"

gcloud spanner rows insert \
    --table=Product \
    --database=$SPANNER_DB_NAME \
    --instance=$SPANNER_INSTANCE_NAME \
    --data=ProductId=7,CategoryId=1,PortfolioId=1,ProductName="Auto Loan",ProductAssetCode=AutLn,ProductClass="Banking LOB"

gcloud spanner rows insert \
    --table=Product \
    --database=$SPANNER_DB_NAME \
    --instance=$SPANNER_INSTANCE_NAME \
    --data=ProductId=8,CategoryId=4,PortfolioId=3,ProductName="Permanent Life Insurance",ProductAssetCode=PermLife,ProductClass="Insurance LOB"

gcloud spanner rows insert \
    --table=Product \
    --database=$SPANNER_DB_NAME \
    --instance=$SPANNER_INSTANCE_NAME \
    --data=ProductId=9,CategoryId=2,PortfolioId=2,ProductName="US Savings Bonds",ProductAssetCode=USSavBond,ProductClass="Investment LOB"

gcloud spanner rows insert \
    --table=Customer \
    --database=$SPANNER_DB_NAME \
    --instance=$SPANNER_INSTANCE_NAME \
    --data=ProductId=9,CategoryId=2,PortfolioId=2,ProductName="US Savings Bonds",ProductAssetCode=USSavBond,ProductClass="Investment LOB"

cat << EOF > manifest.json
{
    "tables": [
        {
            "table_name": "Customer",
            "file_patterns": [
                "$SPANNER_CUSTOMER_DATA_GS_URI"
            ],
            "columns": [
                {"column_name" : "CustomerId", "type_name" : "STRING" },
                {"column_name" : "Name", "type_name" : "STRING" },
                {"column_name" : "Location", "type_name" : "STRING" }
            ]
        }
    ]
}
EOF

gsutil mb gs://$DEVSHELL_PROJECT_ID
gsutil cp manifest.json gs://$DEVSHELL_PROJECT_ID

gcloud dataflow jobs run $DATAFLOW_JOB_NAME \
    --gcs-location gs://dataflow-templates-$REGION/latest/GCS_Text_to_Cloud_Spanner \
    --region $REGION \
    --worker-machine-type e2-medium \
    --staging-location gs://$DEVSHELL_PROJECT_ID/tmp \
    --parameters ^~^instanceId=$SPANNER_INSTANCE_NAME~databaseId=$SPANNER_DB_NAME~spannerHost=https://batch-spanner.googleapis.com~importManifest=gs://$DEVSHELL_PROJECT_ID/manifest.json~columnDelimiter=,~fieldQualifier=\"~trailingDelimiter=true~handleNewLine=false

gcloud spanner databases ddl update $SPANNER_DB_NAME \
--instance=$SPANNER_INSTANCE_NAME \
--ddl='ALTER TABLE Category ADD COLUMN MarketingBudget INT64;'