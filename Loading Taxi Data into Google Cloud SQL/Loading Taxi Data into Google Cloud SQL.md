# [Loading Taxi Data into Google Cloud SQL](https://www.cloudskillsboost.google/games/5521/labs/35625)

## Solution [here]()

### Run the following Commands in CloudShell

```
curl -LO raw.githubusercontent.com/QUICK-GCP-LAB/2-Minutes-Labs-Solutions/main/Analyze%20Images%20with%20the%20Cloud%20Vision%20API%20Challenge%20Lab/arc122.sh

sudo chmod +x arc122.sh

./arc122.sh
```

* When prompted for the password type **Passw0rd** and press Enter.

* Now paste the following content into the command line to create the schema for the trips table:

```
create table trips (
  vendor_id VARCHAR(16),    
  pickup_datetime DATETIME,
  dropoff_datetime DATETIME,
  passenger_count INT,
  trip_distance FLOAT,
  rate_code VARCHAR(16),
  store_and_fwd_flag VARCHAR(16),
  payment_type VARCHAR(16),
  fare_amount FLOAT,
  extra FLOAT,
  mta_tax FLOAT,
  tip_amount FLOAT,
  tolls_amount FLOAT,
  imp_surcharge FLOAT,
  total_amount FLOAT,
  pickup_location_id VARCHAR(16),
  dropoff_location_id VARCHAR(16)
);
```

### Congratulations 🎉 for completing the Lab !

##### *You Have Successfully Demonstrated Your Skills And Determination.*

#### *Well done!*

#### Don't Forget to Join the [Telegram Channel](https://t.me/quickgcplab) & [Discussion group](https://t.me/quickgcplabchats)

# [QUICK GCP LAB](https://www.youtube.com/@quickgcplab)