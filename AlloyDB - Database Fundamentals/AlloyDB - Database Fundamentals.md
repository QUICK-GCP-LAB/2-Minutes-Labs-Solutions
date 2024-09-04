# AlloyDB - Database Fundamentals || [GSP1083](https://www.cloudskillsboost.google/focuses/50122?parent=catalog) ||

## Solution [here]()

### Run the following Commands in CloudShell

```
curl -LO raw.githubusercontent.com/QUICK-GCP-LAB/2-Minutes-Labs-Solutions/main/AlloyDB%20-%20Database%20Fundamentals/gsp1083.sh

sudo chmod +x gsp1083.sh

./gsp1083.sh
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
CREATE TABLE regions (
    region_id bigint NOT NULL,
    region_name varchar(25)
) ;
ALTER TABLE regions ADD PRIMARY KEY (region_id);
```
```
INSERT INTO regions VALUES ( 1, 'Europe' );
INSERT INTO regions VALUES ( 2, 'Americas' );
INSERT INTO regions VALUES ( 3, 'Asia' );
INSERT INTO regions VALUES ( 4, 'Middle East and Africa' );
```
```
gcloud beta alloydb clusters create gcloud-lab-cluster \
    --password=Change3Me \
    --network=peering-network \
    --region=$REGION \
    --project=$DEVSHELL_PROJECT_ID

gcloud beta alloydb instances create gcloud-lab-instance\
    --instance-type=PRIMARY \
    --cpu-count=2 \
    --region=$REGION  \
    --cluster=gcloud-lab-cluster \
    --project=$DEVSHELL_PROJECT_ID
```

### Congratulations 🎉 for completing the Lab !

##### *You Have Successfully Demonstrated Your Skills And Determination.*

#### *Well done!*

#### Don't Forget to Join the [Telegram Channel](https://t.me/quickgcplab) & [Discussion group](https://t.me/quickgcplabchats)

# [QUICK GCP LAB](https://www.youtube.com/@quickgcplab)