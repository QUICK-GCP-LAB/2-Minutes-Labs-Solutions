# Configure Replication and Enable Point-in-Time-Recovery for Cloud SQL for PostgreSQL || [GSP922](https://www.cloudskillsboost.google/focuses/22795?parent=catalog) ||

## 🔑 Solution [here]()

### ⚙️ Execute the Following Commands in Cloud Shell

```
PROJECT_ID=$(gcloud config get-value project)
export CLOUD_SQL_INSTANCE=postgres-orders
gcloud sql instances describe $CLOUD_SQL_INSTANCE

BACKUP_TIME=$(date +"%R")

gcloud sql instances patch $CLOUD_SQL_INSTANCE \
    --backup-start-time=$BACKUP_TIME

  gcloud sql instances patch $CLOUD_SQL_INSTANCE \
     --enable-point-in-time-recovery \
     --retained-transaction-log-days=1

TIMESTAMP=$(date --rfc-3339=seconds)

gcloud sql connect postgres-orders --user=postgres --quiet
```

* enter the below password when prompted. A psql session will start in Cloud Shell.

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
```
INSERT INTO distribution_centers VALUES(-80.1918,25.7617,'Miami FL',11);
SELECT COUNT(*) FROM distribution_centers;
```
```
\q
```
```
export NEW_INSTANCE_NAME=postgres-orders-pitr

# Start the clone operation and capture the operation ID
OPERATION_ID=$(gcloud sql instances clone $CLOUD_SQL_INSTANCE $NEW_INSTANCE_NAME --point-in-time "$TIMESTAMP" --async --format="value(name)")

wait_for_sql_operation() {

    echo "⏳ Waiting for Cloud SQL operation: $OPERATION_ID"

    while true; do
        if gcloud beta sql operations wait "$OPERATION_ID" --project="$PROJECT_ID"; then
            echo "✅ Operation $OPERATION_ID completed successfully!"
            break
        else
            echo "⚠️ Operation $OPERATION_ID is taking longer than expected. Retrying in 5 seconds..."
            sleep 5
        fi
    done
}

wait_for_sql_operation


gcloud sql connect postgres-orders-pitr --user=postgres --quiet
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