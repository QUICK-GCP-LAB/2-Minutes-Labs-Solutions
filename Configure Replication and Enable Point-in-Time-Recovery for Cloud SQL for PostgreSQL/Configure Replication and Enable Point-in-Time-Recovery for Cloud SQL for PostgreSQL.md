# Configure Replication and Enable Point-in-Time-Recovery for Cloud SQL for PostgreSQL || [GSP922](https://www.cloudskillsboost.google/focuses/22795?parent=catalog) ||

## 🔑 Solution [here](https://youtu.be/91LVHWZH9_U)

### ⚙️ Execute the Following Commands in Cloud Shell

```
export PROJECT_ID=$(gcloud config get-value project)
export CLOUD_SQL_INSTANCE=postgres-orders
gcloud sql instances describe $CLOUD_SQL_INSTANCE

export BACKUP_TIME=$(date +"%R")

gcloud sql instances patch $CLOUD_SQL_INSTANCE \
    --backup-start-time=$BACKUP_TIME

  gcloud sql instances patch $CLOUD_SQL_INSTANCE \
     --enable-point-in-time-recovery \
     --retained-transaction-log-days=1

export TIMESTAMP=$(date --rfc-3339=seconds)

gcloud sql connect postgres-orders --user=postgres --quiet
```

* enter the below password when prompted. A psql session will start in Cloud Shell.

```
supersecret!
```
* In psql, change to the orders database:
```
\c orders
```
* When prompted, enter the password again.
```
supersecret!
```
```
SELECT COUNT(*) FROM distribution_centers;
```
```
INSERT INTO distribution_centers VALUES(-80.1918,25.7617,'Miami FL',11);
SELECT COUNT(*) FROM distribution_centers;
```
```
\q
```
```
curl -LO raw.githubusercontent.com/QUICK-GCP-LAB/2-Minutes-Labs-Solutions/refs/heads/main/Configure%20Replication%20and%20Enable%20Point-in-Time-Recovery%20for%20Cloud%20SQL%20for%20PostgreSQL/gsp922.sh

sudo chmod +x *.sh

./*.sh
```
```
supersecret!
```
```
\c orders
```
```
supersecret!
```
```
SELECT COUNT(*) FROM distribution_centers;
```

# 🎉 Woohoo! You Did It! 🎉

Your hard work and determination paid off! 💻
You've successfully completed the lab. **Way to go!** 🚀

### 💬 Stay Connected with Our Community!
👉 Join the conversation and never miss an update:
📢 [Telegram Channel](https://t.me/quickgcplab)
👥 [Discussion Group](https://t.me/quickgcplabchats)

# [QUICK GCP LAB](https://www.youtube.com/@quickgcplab)
