export PROJECT_ID=
export REGION=
export ZONE=

export ALLOYDB_CLUSTER=lab-cluster
export ALLOYDB_CLUSTER_INSTANCE_01="lab-instance"
export ALLOYDB_PASSWORD=Change3Me
export ALLOYDB_NETWORK=peering-network

gcloud alloydb clusters create $ALLOYDB_CLUSTER \
    --password=$ALLOYDB_PASSWORD \
    --network=$ALLOYDB_NETWORK \
    --region=$REGION \
    --project=$PROJECT_ID

gcloud alloydb instances create $ALLOYDB_CLUSTER_INSTANCE_01 \
    --instance-type=PRIMARY \
    --cpu-count=2 \
    --region=$REGION  \
    --cluster=$ALLOYDB_CLUSTER \
    --project=$PROJECT_ID

# BASIC/FULL
gcloud alloydb instances describe $ALLOYDB_CLUSTER_INSTANCE_01 \
    --cluster=$ALLOYDB_CLUSTER \
    --region=$REGION \
    --view=BASIC

export ALLOYDB=`gcloud \
    --format="value(ipAddress)" \
    alloydb instances describe $ALLOYDB_CLUSTER_INSTANCE_01 \
    --cluster=$ALLOYDB_CLUSTER \
    --region=$REGION \
    --view=BASIC`

gcloud compute ssh alloydb-client --zone $ZONE

cat > hrm_load.sql << EOF
CREATE TABLE regions (
    region_id bigint NOT NULL,
    region_name varchar(25)
) ;

ALTER TABLE regions ADD PRIMARY KEY (region_id);

CREATE TABLE regions (
    country_id char(2) NOT NULL,
    country_name varchar(40),
    region_id bigint
) ;

ALTER TABLE countries ADD PRIMARY KEY (country_id);

CREATE TABLE departments (
    department_id smallint NOT NULL,
    department_name varchar(30),
    manager_id integer,
    location_id smallint
) ;

ALTER TABLE departments ADD PRIMARY KEY (department_id);

INSERT INTO regions VALUES ( 1, 'Europe' );
INSERT INTO regions VALUES ( 2, 'Americas' );
INSERT INTO regions VALUES ( 3, 'Asia' );
INSERT INTO regions VALUES ( 4, 'Middle East and Africa' );

INSERT INTO departments VALUES ('IT', 'Italy', 1);
INSERT INTO departments VALUES ('JP', 'Japan', 3);
INSERT INTO departments VALUES ('US', 'United States of America', 2);
INSERT INTO departments VALUES ('CA', 'Canada', 2);
INSERT INTO departments VALUES ('CN', 'China', 3);
INSERT INTO departments VALUES ('IN', 'India', 3);
INSERT INTO departments VALUES ('AU', 'Australia', 3);
INSERT INTO departments VALUES ('ZW', 'Zimbabwe', 4);
INSERT INTO departments VALUES ('SG', 'Singapore', 3);

INSERT INTO departments VALUES (10, 'Administration', 200, 1700);
INSERT INTO departments VALUES (20, 'Marketing', 201, 1800);
INSERT INTO departments VALUES (30, 'Purchasing', 114, 1700);
INSERT INTO departments VALUES (40, 'Human Resources', 203, 2400);
INSERT INTO departments VALUES (50, 'Shipping', 121, 1500);
INSERT INTO departments VALUES (60, 'IT', 103, 1400);

EOF

echo $ALLOYDB  > alloydbip.txt

gcloud alloydb instances describe $$ALLOYDB_CLUSTER_INSTANCE_01 \
    --cluster=$ALLOYDB_CLUSTER \
    --region=$REGION \
    --view=BASIC

export ALLOYDB=ALLOYDB_ADDRESS

psql -h $ALLOYDB -U postgres

gcloud alloydb instances create lab-instance-rp1 \
    --instance-type=READ_POOL \
    --cpu-count=2 \
    --read-pool-node-count=2 \
    --region=$REGION  \
    --cluster=$ALLOYDB_CLUSTER  \
    --project=$PROJECT_ID

gcloud alloydb backups create lab-backup \
    --cluster=$ALLOYDB_CLUSTER \
    --region=$REGION \
    --project=$PROJECT_ID
