# Configuring IAM Permissions with gcloud - AWS || [GSP1126](https://www.cloudskillsboost.google/focuses/60386?parent=catalog) ||

## Solution [here](https://youtu.be/KR1dpJvDv4o)

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
curl -LO raw.githubusercontent.com/QUICK-GCP-LAB/2-Minutes-Labs-Solutions/main/Configuring%20IAM%20Permissions%20with%20gcloud%20-%20AWS/gsp1126-1.sh
sudo chmod +x gsp1126-1.sh
./gsp1126-1.sh
```
```
user2
```
```
curl -LO raw.githubusercontent.com/QUICK-GCP-LAB/2-Minutes-Labs-Solutions/main/Configuring%20IAM%20Permissions%20with%20gcloud%20-%20AWS/gsp1126-2.sh
sudo chmod +x gsp1126-2.sh
./gsp1126-2.sh
```


### Congratulations 🎉 for completing the Lab !

##### *You Have Successfully Demonstrated Your Skills And Determination.*

#### *Well done!*

#### Don't Forget to Join the [Telegram Channel](https://t.me/quickgcplab) & [Discussion group](https://t.me/quickgcplabchats)

# [QUICK GCP LAB](https://www.youtube.com/@quickgcplab)
