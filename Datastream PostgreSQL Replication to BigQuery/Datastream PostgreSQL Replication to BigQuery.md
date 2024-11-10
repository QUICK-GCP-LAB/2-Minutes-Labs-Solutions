# Datastream: PostgreSQL Replication to BigQuery || [GSP1052](https://www.cloudskillsboost.google/focuses/53925?parent=catalog) ||

## Solution [here](https://youtu.be/GVl2jfB7DKA)

### Run the following Commands in CloudShell

```
export 
```
```
curl -LO raw.githubusercontent.com/QUICK-GCP-LAB/2-Minutes-Labs-Solutions/refs/heads/main/Datastream%20PostgreSQL%20Replication%20to%20BigQuery/gsp1052-1.sh

sudo chmod +x gsp1052-1.sh

./gsp1052-1.sh
```

* When prompted for the password, paste the following.

```
pwd
```
```
CREATE SCHEMA IF NOT EXISTS test;

CREATE TABLE IF NOT EXISTS test.example_table (
id  SERIAL PRIMARY KEY,
text_col VARCHAR(50),
int_col INT,
date_col TIMESTAMP
);

ALTER TABLE test.example_table REPLICA IDENTITY DEFAULT; 

INSERT INTO test.example_table (text_col, int_col, date_col) VALUES
('hello', 0, '2020-01-01 00:00:00'),
('goodbye', 1, NULL),
('name', -987, NOW()),
('other', 2786, '2021-01-01 00:00:00');

CREATE PUBLICATION test_publication FOR ALL TABLES;
ALTER USER POSTGRES WITH REPLICATION;
SELECT PG_CREATE_LOGICAL_REPLICATION_SLOT('test_replication', 'pgoutput');
```
```
exit
```
```
curl -LO raw.githubusercontent.com/QUICK-GCP-LAB/2-Minutes-Labs-Solutions/refs/heads/main/Datastream%20PostgreSQL%20Replication%20to%20BigQuery/gsp1052-2.sh

sudo chmod +x gsp1052-2.sh

./gsp1052-2.sh
```

* Use **postgres-cp** as the name and ID of the connection profile.

| Field | Value |
| :---: | :----: |
| Username | **postgres** |
| Password  | **pwd** |
| Database | **postgres** |

* Use **bigquery-cp** as the name and ID of the connection profile.

* Use **test-stream** as the name and ID of the stream

* Specify the replication slot name as **test_replication**

* Specify the publication name as **test_publication**

### Congratulations 🎉 for completing the Lab !

##### *You Have Successfully Demonstrated Your Skills And Determination.*

#### *Well done!*

#### Don't Forget to Join the [Telegram Channel](https://t.me/quickgcplab) & [Discussion group](https://t.me/quickgcplabchats)

# [QUICK GCP LAB](https://www.youtube.com/@quickgcplab)
