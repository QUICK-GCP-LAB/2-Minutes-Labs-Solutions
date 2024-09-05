# Administering an AlloyDB Database || [GSP1086](https://www.cloudskillsboost.google/focuses/100851?parent=catalog) ||

## Solution [here](https://youtu.be/SjV2dOM_TME)

### Run the following Commands in CloudShell

```
export ZONE=$(gcloud compute instances list alloydb-client --format 'csv[no-heading](zone)')

gcloud compute ssh alloydb-client --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet
```
```
export ALLOYDB=
```

* Go to `AlloyDB Clusters` from [here](https://console.cloud.google.com/alloydb/clusters?)

```
echo $ALLOYDB  > alloydbip.txt 
psql -h $ALLOYDB -U postgres
```

* Paste The Following Password

```
Change3Me
```
```
\c postgres
```
```
CREATE EXTENSION IF NOT EXISTS PGAUDIT;
```
```
select extname, extversion from pg_extension where extname = 'pgaudit';
```
```
\q
```
```
exit
```
```
export ZONE=$(gcloud compute instances list alloydb-client --format 'csv[no-heading](zone)')
export REGION="${ZONE%-*}"
gcloud alloydb instances create lab-instance-rp1 \
  --cluster=lab-cluster \
  --region=$REGION \
  --instance-type=READ_POOL \
  --cpu-count=2 \
  --read-pool-node-count=2
```

* Open New Cloudshell tab

```
export ZONE=$(gcloud compute instances list alloydb-client --format 'csv[no-heading](zone)')
export REGION="${ZONE%-*}"
gcloud beta alloydb backups create lab-backup --region=$REGION  --cluster=lab-cluster
```

### Congratulations 🎉 for completing the Lab !

##### *You Have Successfully Demonstrated Your Skills And Determination.*

#### *Well done!*

#### Don't Forget to Join the [Telegram Channel](https://t.me/quickgcplab) & [Discussion group](https://t.me/quickgcplabchats)

# [QUICK GCP LAB](https://www.youtube.com/@quickgcplab)
