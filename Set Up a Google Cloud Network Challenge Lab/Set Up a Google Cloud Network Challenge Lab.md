# Set Up a Google Cloud Network: Challenge Lab || [GSP314](https://www.cloudskillsboost.google/focuses/10417?parent=catalog) ||

## Solution [here]()

### Task 1: Migrate a stand-alone PostgreSQL database to a Cloud SQL for PostgreSQL instance

Task 1: Migrate a stand-alone PostgreSQL database to a Cloud SQL for PostgreSQL instance

1. Enable the [Database Migration API](https://console.cloud.google.com/marketplace/product/google/datamigration.googleapis.com) and the [Service Networking API](https://console.cloud.google.com/marketplace/product/google/servicenetworking.googleapis.com)

2. Go to [VM instances](https://console.cloud.google.com/compute/instances)

3. Click `SSH` next to `antern-postgresql-vm`

### Run the following Commands in `SSH`

```
sudo apt install postgresql-13-pglogical
```
```
sudo su - postgres -c "gsutil cp gs://cloud-training/gsp918/pg_hba_append.conf ."
sudo su - postgres -c "gsutil cp gs://cloud-training/gsp918/postgresql_append.conf ."
sudo su - postgres -c "cat pg_hba_append.conf >> /etc/postgresql/13/main/pg_hba.conf"
sudo su - postgres -c "cat postgresql_append.conf >> /etc/postgresql/13/main/postgresql.conf"
sudo systemctl restart postgresql@13-main
```
```
sudo su - postgres
psql
```
```
\c postgres;
CREATE EXTENSION pglogical;
\c orders;
CREATE EXTENSION pglogical;
\c gmemegen_db;
CREATE EXTENSION pglogical;
```

* NOTE: Replace `[MIGRATION ADMINE]` with your `Postgres Migration Username`

```
CREATE USER [MIGRATION ADMINE] PASSWORD 'DMS_1s_cool!';
ALTER DATABASE orders OWNER TO [MIGRATION ADMINE];
ALTER ROLE [MIGRATION ADMINE] WITH REPLICATION;

\c postgres;
GRANT USAGE ON SCHEMA pglogical TO [MIGRATION ADMINE];
GRANT ALL ON SCHEMA pglogical TO [MIGRATION ADMINE];
GRANT SELECT ON pglogical.tables TO [MIGRATION ADMINE];
GRANT SELECT ON pglogical.depend TO [MIGRATION ADMINE];
GRANT SELECT ON pglogical.local_node TO [MIGRATION ADMINE];
GRANT SELECT ON pglogical.local_sync_status TO [MIGRATION ADMINE];
GRANT SELECT ON pglogical.node TO [MIGRATION ADMINE];
GRANT SELECT ON pglogical.node_interface TO [MIGRATION ADMINE];
GRANT SELECT ON pglogical.queue TO [MIGRATION ADMINE];
GRANT SELECT ON pglogical.replication_set TO [MIGRATION ADMINE];
GRANT SELECT ON pglogical.replication_set_seq TO [MIGRATION ADMINE];
GRANT SELECT ON pglogical.replication_set_table TO [MIGRATION ADMINE];
GRANT SELECT ON pglogical.sequence_state TO [MIGRATION ADMINE];
GRANT SELECT ON pglogical.subscription TO [MIGRATION ADMINE];

\c orders;
GRANT USAGE ON SCHEMA pglogical TO [MIGRATION ADMINE];
GRANT ALL ON SCHEMA pglogical TO [MIGRATION ADMINE];
GRANT SELECT ON pglogical.tables TO [MIGRATION ADMINE];
GRANT SELECT ON pglogical.depend TO [MIGRATION ADMINE];
GRANT SELECT ON pglogical.local_node TO [MIGRATION ADMINE];
GRANT SELECT ON pglogical.local_sync_status TO [MIGRATION ADMINE];
GRANT SELECT ON pglogical.node TO [MIGRATION ADMINE];
GRANT SELECT ON pglogical.node_interface TO [MIGRATION ADMINE];
GRANT SELECT ON pglogical.queue TO [MIGRATION ADMINE];
GRANT SELECT ON pglogical.replication_set TO [MIGRATION ADMINE];
GRANT SELECT ON pglogical.replication_set_seq TO [MIGRATION ADMINE];
GRANT SELECT ON pglogical.replication_set_table TO [MIGRATION ADMINE];
GRANT SELECT ON pglogical.sequence_state TO [MIGRATION ADMINE];
GRANT SELECT ON pglogical.subscription TO [MIGRATION ADMINE];

GRANT USAGE ON SCHEMA public TO [MIGRATION ADMINE];
GRANT ALL ON SCHEMA public TO [MIGRATION ADMINE];
GRANT SELECT ON public.distribution_centers TO [MIGRATION ADMINE];
GRANT SELECT ON public.inventory_items TO [MIGRATION ADMINE];
GRANT SELECT ON public.order_items TO [MIGRATION ADMINE];
GRANT SELECT ON public.products TO [MIGRATION ADMINE];
GRANT SELECT ON public.users TO [MIGRATION ADMINE];

\c gmemegen_db;
GRANT USAGE ON SCHEMA pglogical TO [MIGRATION ADMINE];
GRANT ALL ON SCHEMA pglogical TO [MIGRATION ADMINE];
GRANT SELECT ON pglogical.tables TO [MIGRATION ADMINE];
GRANT SELECT ON pglogical.depend TO [MIGRATION ADMINE];
GRANT SELECT ON pglogical.local_node TO [MIGRATION ADMINE];
GRANT SELECT ON pglogical.local_sync_status TO [MIGRATION ADMINE];
GRANT SELECT ON pglogical.node TO [MIGRATION ADMINE];
GRANT SELECT ON pglogical.node_interface TO [MIGRATION ADMINE];
GRANT SELECT ON pglogical.queue TO [MIGRATION ADMINE];
GRANT SELECT ON pglogical.replication_set TO [MIGRATION ADMINE];
GRANT SELECT ON pglogical.replication_set_seq TO [MIGRATION ADMINE];
GRANT SELECT ON pglogical.replication_set_table TO [MIGRATION ADMINE];
GRANT SELECT ON pglogical.sequence_state TO [MIGRATION ADMINE];
GRANT SELECT ON pglogical.subscription TO [MIGRATION ADMINE];

GRANT USAGE ON SCHEMA public TO [MIGRATION ADMINE];
GRANT ALL ON SCHEMA public TO [MIGRATION ADMINE];
GRANT SELECT ON public.meme TO [MIGRATION ADMINE];

\c orders;
\dt
ALTER TABLE public.distribution_centers OWNER TO [MIGRATION ADMINE];
ALTER TABLE public.inventory_items OWNER TO [MIGRATION ADMINE];
ALTER TABLE public.order_items OWNER TO [MIGRATION ADMINE];
ALTER TABLE public.products OWNER TO [MIGRATION ADMINE];
ALTER TABLE public.users OWNER TO [MIGRATION ADMINE];
\dt

ALTER TABLE public.inventory_items ADD PRIMARY KEY(id);
\q 
exit
```

Go to [CREATE MIGRATION JOB](https://console.cloud.google.com/dbmigration/migrations/create)

* NOW FOLLOW VIDEO INSTRUCTIONS

### Task 2: Update permissions and add IAM roles to users

Go to [IAM](https://console.cloud.google.com/iam-admin/iam) and follow video instructions

### Task 3: Create networks and firewalls

* Note: For this task, you will need to log in to the `Cymbal Project` with the `Cymbal Owner credentials`.

### Run the following Commands in CloudShell

### Assign Veriables
```
export VPC_NAME=
export SUBNET_A=
export REGION_A=
export SUBNET_B=
export REGION_B=
export FIREWALL_RULE_NAME_1=
export FIREWALL_RULE_NAME_2=
export FIREWALL_RULE_NAME_3=
```
```
curl -LO raw.githubusercontent.com/QUICK-GCP-LAB/2-Minutes-Labs-Solutions/main/Set%20Up%20a%20Google%20Cloud%20Network%20Challenge%20Lab/gsp314.sh

sudo chmod +x gsp314.sh

./gsp314.sh
```

### Task 4: Troubleshoot and fix a broken GKE cluster

Go to [Create sink](https://console.cloud.google.com/logs/router/sink)

* PASTE the following in `Build inclusion filter`

```
resource.type=REPLACE HERE;
severity=ERROR
```

* Go to [IAM](https://console.cloud.google.com/iam-admin/iam)


### Congratulations 🎉 for completing the Challenge Lab !

##### *You Have Successfully Demonstrated Your Skills And Determination.*

#### *Well done!*

#### Don't Forget to Join the [Telegram Channel](https://t.me/QuickGcpLab) & [Discussion group](https://t.me/QuickGcpLabChats)

# [QUICK GCP LAB](https://www.youtube.com/@quickgcplab)
