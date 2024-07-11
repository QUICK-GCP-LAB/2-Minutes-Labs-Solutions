# Deploying an Open Source Cassandra™ Database using the GCP Marketplace || [GSP704](https://www.cloudskillsboost.google/focuses/10538?parent=catalog) ||

## Solution [here](https://youtu.be/2zZmSJTX9Ps)

* Go to `Apache Cassandra packaged by Bitnami` from [here](https://console.cloud.google.com/marketplace/product/bitnami-launchpad/cassandra?)

### Run the following Commands in CloudShell

```
gcloud compute ssh --zone "us-central1-f" "cassandra-1-vm" --project "$DEVSHELL_PROJECT_ID" --quiet
```
```
export PSW=
```
```
export USER=cassandra
cqlsh -u $USER -p $PSW
```
```
CREATE KEYSPACE space_flights WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1};

CREATE TABLE space_flights.catalog (
    spacecraft_name text,
    journey_id timeuuid,
    start timestamp,
    end timestamp,
    active boolean,
    summary text,
    PRIMARY KEY ((spacecraft_name), journey_id)
    ) WITH CLUSTERING ORDER BY (journey_id desc);

DESCRIBE KEYSPACE space_flights;

DESCRIBE TABLE space_flights.catalog;

INSERT INTO space_flights.catalog (spacecraft_name, journey_id, start, end, active, summary) VALUES ('vostok1', 805b1a00-5673-11a8-8080-808080808080, '1961-4-12T06:07:00+0000', '1961-4-12T07:55:00+0000', False, 'First manned spaceflight. Completed one Earth orbit.');
INSERT INTO space_flights.catalog (spacecraft_name, journey_id, start, end, active, summary) VALUES ('mercury-redstone3', 2396fc00-68cd-11a8-8080-808080808080, '1961-5-5T14:34:00+0000', '1961-5-5T14:49:00+0000', False, 'First American manned suborbital spaceflight (altitude 187 kilometres, 116 miles).');
INSERT INTO space_flights.catalog (spacecraft_name, journey_id, start, end, active, summary) VALUES ('mercury-redstone4', 2d2f1800-a53c-11a8-8080-808080808080, '1961-7-21T12:20:00+0000', '1961-7-21T12:35:00+0000', False, 'Second American manned suborbital flight (altitude 118.26mi, 190km).');
INSERT INTO space_flights.catalog (spacecraft_name, journey_id, start, end, active, summary) VALUES ('vostok2', 5c2ac800-b191-11a8-8080-808080808080, '1961-8-6T05:00:00+0000', '1961-8-7T05:01:00+0000', False, 'Day-long flight. Completed 17 Earth orbits. Brief manual control by pilot.');
INSERT INTO space_flights.catalog (spacecraft_name, journey_id, start, end, active, summary) VALUES ('mercury-atlas6', 8c7b3200-4d82-11a9-8080-808080808080, '1962-2-20T15:47:00+0000', '1962-2-20T20:42:00+0000', False, 'First American manned orbital flight. Completed three orbits.');
INSERT INTO space_flights.catalog (spacecraft_name, journey_id, start, end, active, summary) VALUES ('mercury-atlas7', e9d69600-9685-11a9-8080-808080808080, '1962-5-24T13:45:00+0000', '1962-5-24T18:41:00+0000', False, 'First manual retrofire. Earth photography and study of liquids in weightless conditions.');
INSERT INTO space_flights.catalog (spacecraft_name, journey_id, start, end, active, summary) VALUES ('vostok3', ff31b400-d46d-11a9-8080-808080808080, '1962-8-11T08:30:00+0000', '1962-8-15T06:52:00+0000', False, 'First instance of two manned spacecraft in orbit simultaneously.');
INSERT INTO space_flights.catalog (spacecraft_name, journey_id, start, end, active, summary) VALUES ('vostok4', 403fcc00-d533-11a9-8080-808080808080, '1962-8-12T08:02:00+0000', '1962-8-15T06:59:00+0000', False, 'First instance of two manned spacecraft in orbit simultaneously.');
INSERT INTO space_flights.catalog (spacecraft_name, journey_id, start, end, active, summary) VALUES ('mercury-atlas8', 977b6200-fe3b-11a9-8080-808080808080, '1962-10-3T13:15:00+0000', '1962-10-3T22:28:00+0000', False, 'First flawless Mercury mission.');

select * from space_flights.catalog;

SELECT * FROM space_flights.catalog WHERE spacecraft_name = 'vostok2';

exit
```

### Congratulations 🎉 for completing the Lab !

##### *You Have Successfully Demonstrated Your Skills And Determination.*

#### *Well done!*

#### Don't Forget to Join the [Telegram Channel](https://t.me/quickgcplab) & [Discussion group](https://t.me/quickgcplabchats)

# [QUICK GCP LAB](https://www.youtube.com/@quickgcplab)
