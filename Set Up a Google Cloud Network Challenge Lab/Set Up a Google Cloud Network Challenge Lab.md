# Set Up a Google Cloud Network: Challenge Lab || [GSP314](https://www.cloudskillsboost.google/focuses/10417?parent=catalog) ||

## Solution [here](https://youtu.be/joyGvSMX-9I)

### Task 1: Migrate a stand-alone PostgreSQL database to a Cloud SQL for PostgreSQL instance
```
curl -LO raw.githubusercontent.com/QUICK-GCP-LAB/2-Minutes-Labs-Solutions/main/Set%20Up%20a%20Google%20Cloud%20Network%20Challenge%20Lab/gsp314-1.sh

sudo chmod +x gsp314-1.sh

./gsp314-1.sh
```
```
sudo apt-get update
sudo apt-get install -y postgresql-13-pglogical

sudo su - postgres -c "gsutil cp gs://cloud-training/gsp918/pg_hba_append.conf ."
sudo su - postgres -c "gsutil cp gs://cloud-training/gsp918/postgresql_append.conf ."
sudo su - postgres -c "cat pg_hba_append.conf >> /etc/postgresql/13/main/pg_hba.conf"
sudo su - postgres -c "cat postgresql_append.conf >> /etc/postgresql/13/main/postgresql.conf"
sudo systemctl restart postgresql@13-main
sudo su - postgres
```
```
psql
```
```
\set user REPLACE_HERE
```
```
\c postgres;
```
```
CREATE EXTENSION pglogical;
```
```
\c orders;
```
```
CREATE EXTENSION pglogical;
```
```
CREATE DATABASE gmemegen_db;
```
```
\c gmemegen_db;
```
```
CREATE EXTENSION pglogical;
```
```
\l
```
```
CREATE USER :user PASSWORD 'DMS_1s_cool!';
GRANT ALL PRIVILEGES ON DATABASE orders TO :user;
ALTER DATABASE orders OWNER TO :user;
ALTER ROLE :user WITH REPLICATION;
```
```
\c postgres;
```
```
GRANT USAGE ON SCHEMA pglogical TO :user;
GRANT ALL ON SCHEMA pglogical TO :user;

GRANT SELECT ON pglogical.tables TO :user;
GRANT SELECT ON pglogical.depend TO :user;
GRANT SELECT ON pglogical.local_node TO :user;
GRANT SELECT ON pglogical.local_sync_status TO :user;
GRANT SELECT ON pglogical.node TO :user;
GRANT SELECT ON pglogical.node_interface TO :user;
GRANT SELECT ON pglogical.queue TO :user;
GRANT SELECT ON pglogical.replication_set TO :user;
GRANT SELECT ON pglogical.replication_set_seq TO :user;
GRANT SELECT ON pglogical.replication_set_table TO :user;
GRANT SELECT ON pglogical.sequence_state TO :user;
GRANT SELECT ON pglogical.subscription TO :user;
```
```
\c orders;
```
```
GRANT USAGE ON SCHEMA pglogical TO :user;
GRANT ALL ON SCHEMA pglogical TO :user;

GRANT SELECT ON pglogical.tables TO :user;
GRANT SELECT ON pglogical.depend TO :user;
GRANT SELECT ON pglogical.local_node TO :user;
GRANT SELECT ON pglogical.local_sync_status TO :user;
GRANT SELECT ON pglogical.node TO :user;
GRANT SELECT ON pglogical.node_interface TO :user;
GRANT SELECT ON pglogical.queue TO :user;
GRANT SELECT ON pglogical.replication_set TO :user;
GRANT SELECT ON pglogical.replication_set_seq TO :user;
GRANT SELECT ON pglogical.replication_set_table TO :user;
GRANT SELECT ON pglogical.sequence_state TO :user;
GRANT SELECT ON pglogical.subscription TO :user;
```
```
GRANT USAGE ON SCHEMA public TO :user;
GRANT ALL ON SCHEMA public TO :user;

GRANT SELECT ON public.distribution_centers TO :user;
GRANT SELECT ON public.inventory_items TO :user;
GRANT SELECT ON public.order_items TO :user;
GRANT SELECT ON public.products TO :user;
GRANT SELECT ON public.users TO :user;
```
```
\c gmemegen_db;
```
```
GRANT USAGE ON SCHEMA pglogical TO :user;
GRANT ALL ON SCHEMA pglogical TO :user;

GRANT SELECT ON pglogical.tables TO :user;
GRANT SELECT ON pglogical.depend TO :user;
GRANT SELECT ON pglogical.local_node TO :user;
GRANT SELECT ON pglogical.local_sync_status TO :user;
GRANT SELECT ON pglogical.node TO :user;
GRANT SELECT ON pglogical.node_interface TO :user;
GRANT SELECT ON pglogical.queue TO :user;
GRANT SELECT ON pglogical.replication_set TO :user;
GRANT SELECT ON pglogical.replication_set_seq TO :user;
GRANT SELECT ON pglogical.replication_set_table TO :user;
GRANT SELECT ON pglogical.sequence_state TO :user;
GRANT SELECT ON pglogical.subscription TO :user;
```
```
GRANT USAGE ON SCHEMA public TO :user;
GRANT ALL ON SCHEMA public TO :user;
```
```
\c orders;
\dt
```
```
ALTER TABLE public.distribution_centers OWNER TO :user;
ALTER TABLE public.inventory_items OWNER TO :user;
ALTER TABLE public.order_items OWNER TO :user;
ALTER TABLE public.products OWNER TO :user;
ALTER TABLE public.users OWNER TO :user;
\dt
```
```
ALTER TABLE public.inventory_items ADD PRIMARY KEY(id);
\q 
```
```
exit
```
```
exit
```
```
export ZONE=$(gcloud compute instances list antern-postgresql-vm --format 'csv[no-heading](zone)')

export VM_INT_IP=$(gcloud compute instances describe antern-postgresql-vm --zone=$ZONE \
  --format='get(networkInterfaces[0].networkIP)')
echo $VM_INT_IP
```

* Go to [Create a migration job](https://console.cloud.google.com/dbmigration/migrations/create)

* Now Follow [Video's](https://youtu.be/joyGvSMX-9I) Instructions

### Task 2: Update permissions and add IAM roles to users

* Go to [IAM](https://console.cloud.google.com/iam-admin/iam) and follow [Video's](https://youtu.be/joyGvSMX-9I) instructions

### Task 3: Create networks and firewalls & Task 4: Troubleshoot and fix a broken GKE cluster

* Note: For this task, you will need to log in to the `Cymbal Project` with the `Cymbal Owner credentials`.

### Run the following Commands in CloudShell

### Assign Veriables
```
export VPC_NAME=
export SUBNET_A=
export REGION_A=
export SUBNET_B=
export REGION_B=
export FIREWALL_1=
export FIREWALL_2=
export FIREWALL_3=
export SINK_NAME=
```
```
curl -LO raw.githubusercontent.com/QUICK-GCP-LAB/2-Minutes-Labs-Solutions/main/Set%20Up%20a%20Google%20Cloud%20Network%20Challenge%20Lab/gsp314-2.sh

sudo chmod +x gsp314-2.sh

./gsp314-2.sh
```

* Go to [IAM](https://console.cloud.google.com/iam-admin/iam) and follow [Video's](https://youtu.be/joyGvSMX-9I) instructions


### Congratulations 🎉 for completing the Challenge Lab !

##### *You Have Successfully Demonstrated Your Skills And Determination.*

#### *Well done!*

#### Don't Forget to Join the [Telegram Channel](https://t.me/quickgcplab) & [Discussion group](https://t.me/quickgcplabchats)

# [QUICK GCP LAB](https://www.youtube.com/@quickgcplab)
