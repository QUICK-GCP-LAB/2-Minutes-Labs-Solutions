# Configuring IAM Permissions with gcloud - AWS || [GSP1126](https://www.cloudskillsboost.google/focuses/60386?parent=catalog) ||

## Solution [here](https://youtu.be/4wASm1F8qbc)

### Run the following Commands in CloudShell

```
export ZONE=$(gcloud compute instances list debian-clean --format 'csv[no-heading](zone)')
gcloud compute ssh debian-clean --zone=$ZONE --quiet
```
### Assign Veriables in `SSH`
```
export USER2=
export PROJECT2=
```
```
export ZONE=$(gcloud compute instances list debian-clean --format 'csv[no-heading](zone)')
gcloud --version
gcloud auth login --no-launch-browser --quiet
```
```
curl -LO raw.githubusercontent.com/QUICK-GCP-LAB/2-Minutes-Labs-Solutions/main/Configuring%20IAM%20Permissions%20with%20gcloud%20-%20AWS/gsp1126.sh
sudo chmod +x gsp1126.sh
./gsp1126.sh
```
```
user2
```
```
gcloud compute instances create lab-2 --machine-type=e2-standard-2
gcloud config configurations activate default
gcloud config configurations activate user2
echo "export PROJECTID2=$PROJECT2" >> ~/.bashrc
. ~/.bashrc
gcloud config set project $PROJECTID2 --quiet
gcloud config configurations activate default
sudo apt -y install jq
echo "export USERID2=$USER2" >> ~/.bashrc
. ~/.bashrc
gcloud projects add-iam-policy-binding $PROJECTID2 --member user:$USERID2 --role=roles/viewer
gcloud config configurations activate user2
gcloud config set project $PROJECTID2
gcloud compute instances create lab-2 --machine-type=e2-standard-2
gcloud config configurations activate default
gcloud iam roles create devops --project $PROJECTID2 --permissions "compute.instances.create,compute.instances.delete,compute.instances.start,compute.instances.stop,compute.instances.update,compute.disks.create,compute.subnetworks.use,compute.subnetworks.useExternalIp,compute.instances.setMetadata,compute.instances.setServiceAccount"
gcloud projects add-iam-policy-binding $PROJECTID2 --member user:$USERID2 --role=roles/iam.serviceAccountUser
gcloud projects add-iam-policy-binding $PROJECTID2 --member user:$USERID2 --role=projects/$PROJECTID2/roles/devops
gcloud config configurations activate user2
gcloud compute instances create lab-2 --machine-type=e2-standard-2
gcloud config configurations activate default
gcloud config set project $PROJECTID2
gcloud iam service-accounts create devops --display-name devops
gcloud iam service-accounts list  --filter "displayName=devops"
SA=$(gcloud iam service-accounts list --format="value(email)" --filter "displayName=devops")
gcloud projects add-iam-policy-binding $PROJECTID2 --member serviceAccount:$SA --role=roles/iam.serviceAccountUser
gcloud projects add-iam-policy-binding $PROJECTID2 --member serviceAccount:$SA --role=roles/compute.instanceAdmin
gcloud compute instances create lab-3 --machine-type=e2-standard-2 --service-account $SA --scopes "https://www.googleapis.com/auth/compute"
```


### Congratulations 🎉 for completing the Lab !

##### *You Have Successfully Demonstrated Your Skills And Determination.*

#### *Well done!*

#### Don't Forget to Join the [Telegram Channel](https://t.me/quickgcplab) & [Discussion group](https://t.me/quickgcplabchats)

# [QUICK GCP LAB](https://www.youtube.com/@quickgcplab)
