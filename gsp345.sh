
export PROJECT_ID=qwiklabs-gcp-03-dd27ab307bbf
export REGION=us-west1
export ZONE=us-west1-c
export BUCKET_NAME=tf-bucket-010813
export LOCATION="US"
export MODULE_VERSION=6.0.0
export NETWORK_NAME=tf-vpc-604365

mkdir lab
cd lab
touch {main,variables}.tf
mkdir -p modules/{instances,storage}
touch modules/{instances,storage}/{outputs,variables}.tf
touch modules/instances/instances.tf
touch modules/storage/storage.tf

cat > main.tf <<EOF
terraform {
  required_version = ">= 0.13.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "< 5.0, >= 3.83"
    }
  }

  backend "local" {
    path = "terraform/state/terraform.tfstate"
  }

  #backend "gcs" {
  #  bucket  = "$BUCKET_NAME"
  #  prefix  = "terraform/state"
  #}
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}
EOF

cat > variables.tf <<EOF
variable "project_id" {
  description = "The project ID to host the network in"
  default     = "${PROJECT_ID}"
}

variable "region" {
  description = "region of resources"
  default     = "${REGION}"
}

variable "zone" {
  description = "zone of resources"
  default     = "${ZONE}"
}
EOF

terraform init

# Task 2
cat >> main.tf <<EOF

module "instances" {
  source = "./modules/instances"
  project_id = var.project_id
  region = var.region
  zone = var.zone
}
EOF

cat > modules/instances/variables.tf <<EOF
variable "project_id" {
  description = "The project ID to host the network in"
}

variable "region" {
  description = "region of resources"
}

variable "zone" {
  description = "zone of resources"
}
EOF

gcloud compute instances describe tf-instance-1 --zone $ZONE
gcloud compute instances describe test-instance --format="yaml(id,name,status,disks,machine_type,network)"

gcloud compute instances describe tf-instance-2

cat > modules/instances/instances.tf <<EOF
resource "google_compute_instance" "tf-instance-1" {
  name         = "tf-instance-1"
  machine_type = "e2-micro"
  zone         = var.zone
  
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = "default"
  }

  metadata_startup_script = <<-EOT
        #/bin/bash
    EOT

  allow_stopping_for_update = true
}

resource "google_compute_instance" "tf-instance-2" {
  name         = "tf-instance-2"
  machine_type = "e2-micro"
  zone         = var.zone
  
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = "default"
  }

  metadata_startup_script = <<-EOT
        #/bin/bash
    EOT

  allow_stopping_for_update = true
}
EOF

terraform init
terraform import module.instances.google_compute_instance.tf-instance-1 tf-instance-1-id
terraform import module.instances.google_compute_instance.tf-instance-2 tf-instance-2-id

cat >> variables.tf <<EOF

variable "bucket_name" {
  description = "bucket name"
  default = "${BUCKET_NAME}"
}

variable "location" {
  description = "location"
  default = "US"
}

variable "force_destroy" {
  type = bool
  description = "force destroy"
  default = true
}

variable "uniform_bucket_level_access" {
  type = bool
  description = "uniform bucket level access"
  default = true
}
EOF

cat >> main.tf <<EOF

module "storage" {
  source = "./modules/storage"
  project_id = var.project_id
  bucket_name = var.bucket_name
  location = var.location
  force_destroy = var.force_destroy
  uniform_bucket_level_access = var.uniform_bucket_level_access
}
EOF

cat > modules/storage/variables.tf <<EOF
variable "project_id" {
  description = "project id"
}

variable "bucket_name" {
  description = "bucket name"
}

variable "location" {
  description = "location"
}

variable "force_destroy" {
  type = bool
  description = "force destroy"
}

variable "uniform_bucket_level_access" {
  type = bool
  description = "uniform bucket level access"
}
EOF

cat > modules/storage/storage.tf <<EOF
resource "google_storage_bucket" "bucket" {
  name               = var.bucket_name
  project            = var.project_id
  location           = var.location
  force_destroy      = var.force_destroy
  uniform_bucket_level_access = var.uniform_bucket_level_access
}
EOF

terraform init
terraform plan
terraform apply 

# edit backennd
echo $BUCKET_NAME

backend "gcs" {
    bucket  = "$BUCKET_NAME"
    prefix  = "terraform/state"
}

terraform init -migrate-state

# Task 4
# add new instance

cat >> variables.tf <<EOF

variable "network_name" {
  description = "network name"
  default = "${NETWORK_NAME}"
}
EOF

cat >> main.tf <<EOF
module "vpc" {
    source  = "terraform-google-modules/network/google"
    version = "~> ${MODULE_VERSION}"

    project_id   = var.project_id
    network_name = var.network_name
    routing_mode = "GLOBAL"

    subnets = [
        {
            subnet_name           = "subnet-01"
            subnet_ip             = "10.10.10.0/24"
            subnet_region         = var.region
        },
        {
            subnet_name           = "subnet-02"
            subnet_ip             = "10.10.20.0/24"
            subnet_region         = var.region
            subnet_private_access = "true"
            subnet_flow_logs      = "true"
            description           = "This subnet has a description"
        }
    ]
}
EOF

terraform init
terraform apply -auto-approve

# edit config
# network_interface {
#  network = "$NETWORK_NAME"
#     subnetwork = "subnet-01"
#  }
# }
# network_interface {
#  network = "$NETWORK_NAME"
#     subnetwork = "subnet-02"
#  }
# }

cat >> main.tf <<EOF
resource "google_compute_firewall" "tf-firewall" {
  name    = "tf-firewall"
  network = "projects/${PROJECT_ID}/global/networks/${NETWORK_NAME}"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_tags = ["web"]
  source_ranges = ["0.0.0.0/0"]
}
EOF

terraform init
terraform apply -auto-approve

gcloud beta network-management connectivity-tests create terraform-network-check-1 \
    --destination-instance=projects/${PROJECT_ID}/zones/${ZONE}/instances/tf-instance-2 \
    --destination-ip-address=10.10.20.2 \
    --destination-network=projects/${PROJECT_ID}/global/networks/${NETWORK_NAME} \
    --destination-port=80 \
    --protocol=TCP \
    --source-instance=projects/${PROJECT_ID}/zones/${ZONE}/instances/tf-instance-1 \
    --source-ip-address=10.10.20.3 \
    --source-network=projects/${PROJECT_ID}/global/networks/${NETWORK_NAME} \
    --project=${PROJECT_ID}