export REGION=
export ZONE=
export PROJECT_ID=

export NETWORK_NAME=

gcloud compute networks create $NETWORK_NAME --project=$PROJECT_ID --subnet-mode=custom --mtu=1460 --bgp-routing-mode=regional

gcloud compute networks subnets create NAME --project=qwiklabs-gcp-01-6fd1adb392ad --range=IP_RANGE --stack-type=IPV4_ONLY --network=securenetwork --region=REGION

gcloud compute --project=qwiklabs-gcp-01-6fd1adb392ad firewall-rules create allow-rdp --direction=INGRESS --priority=1000 --network=securenetwork --action=ALLOW --rules=tcp:3389 --source-ranges=0.0.0.0/0 --target-tags=jump

gcloud compute instances create vm-securehost --project=qwiklabs-gcp-01-6fd1adb392ad --zone=us-east4-b --machine-type=e2-medium --network-interface=stack-type=IPV4_ONLY,subnet=securenetwork-us-east4,no-address --network-interface=stack-type=IPV4_ONLY,subnet=default,no-address --metadata=enable-oslogin=true --maintenance-policy=MIGRATE --provisioning-model=STANDARD --service-account=561007280224-compute@developer.gserviceaccount.com --scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/trace.append --create-disk=auto-delete=yes,boot=yes,device-name=vm-securehost,image=projects/windows-cloud/global/images/windows-server-2016-dc-v20240328,mode=rw,size=50,type=projects/qwiklabs-gcp-01-6fd1adb392ad/zones/us-east4-b/diskTypes/pd-balanced --no-shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring --labels=goog-ec-src=vm_add-gcloud --reservation-affinity=any

gcloud compute instances create vm-bastionhost --project=qwiklabs-gcp-01-6fd1adb392ad --zone=us-east4-b --machine-type=e2-medium --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=securenetwork-us-east4 --network-interface=stack-type=IPV4_ONLY,subnet=default,no-address --metadata=enable-oslogin=true --maintenance-policy=MIGRATE --provisioning-model=STANDARD --service-account=561007280224-compute@developer.gserviceaccount.com --scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/trace.append --tags=jump --create-disk=auto-delete=yes,boot=yes,device-name=vm-bastionhost,image=projects/windows-cloud/global/images/windows-server-2016-dc-v20240328,mode=rw,size=50,type=projects/qwiklabs-gcp-01-6fd1adb392ad/zones/us-east4-b/diskTypes/pd-balanced --no-shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring --labels=goog-ec-src=vm_add-gcloud --reservation-affinity=any

gcloud compute reset-windows-password vm-bastionhost --user app_admin --zone us-east4-b

```
ip_address: 34.85.189.14
password:   -ef~|&oZ:yXX8wK
username:   app_admin
```

gcloud compute reset-windows-password vm-securehost --user app_admin --zone us-east4-b
```
password: _?Vu]AKCk}ZdM[:
username: app_admin
```