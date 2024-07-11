# Engineer Data for Predictive Modeling with BigQuery ML: Challenge Lab || [GSP327](https://www.cloudskillsboost.google/focuses/12379?parent=catalog) ||

## Solution [here](https://youtu.be/-YJEXngsFJQ)

### Run the following Queries in BigQuery Editor

### Task 1. Clean your training data

* Replace `TABLE_NAME` , `FARE_AMOUNT_NAME` , `TRIP_DISTANCE_NO` , `FARE_AMOUNT` & `PASSENGER_COUNT`

```
CREATE OR REPLACE TABLE
  taxirides.TABLE_NAME AS
SELECT
  (tolls_amount + fare_amount) AS FARE_AMOUNT_NAME,
  pickup_datetime,
  pickup_longitude AS pickuplon,
  pickup_latitude AS pickuplat,
  dropoff_longitude AS dropofflon,
  dropoff_latitude AS dropofflat,
  passenger_count AS passengers,
FROM
  taxirides.historical_taxi_rides_raw
WHERE
  RAND() < 0.001
  AND trip_distance > TRIP_DISTANCE_NO
  AND fare_amount >= FARE_AMOUNT
  AND pickup_longitude > -78
  AND pickup_longitude < -70
  AND dropoff_longitude > -78
  AND dropoff_longitude < -70
  AND pickup_latitude > 37
  AND pickup_latitude < 45
  AND dropoff_latitude > 37
  AND dropoff_latitude < 45
  AND passenger_count > PASSENGER_COUNT
```
### Task 2. Create a BigQuery ML model

* Replace `MODEL_NAME` , `FARE_AMOUNT_NAME` & `TABLE_NAME`

```
CREATE OR REPLACE MODEL taxirides.MODEL_NAME
TRANSFORM(
  * EXCEPT(pickup_datetime)

  , ST_Distance(ST_GeogPoint(pickuplon, pickuplat), ST_GeogPoint(dropofflon, dropofflat)) AS euclidean
  , CAST(EXTRACT(DAYOFWEEK FROM pickup_datetime) AS STRING) AS dayofweek
  , CAST(EXTRACT(HOUR FROM pickup_datetime) AS STRING) AS hourofday
)
OPTIONS(input_label_cols=['FARE_AMOUNT_NAME'], model_type='linear_reg')
AS

SELECT * FROM taxirides.TABLE_NAME
```

### Task 3. Perform a batch prediction on new data

* Replace `MODEL_NAME`

```
CREATE OR REPLACE TABLE taxirides.2015_fare_amount_predictions
  AS
SELECT * FROM ML.PREDICT(MODEL taxirides.MODEL_NAME,(
  SELECT * FROM taxirides.report_prediction_data)
)
```

### Congratulations 🎉 for Completing the Lab !

##### *You Have Successfully Demonstrated Your Skills And Determination.*

#### *Well done!*

#### Don't Forget to Join the [Telegram Channel](https://t.me/quickgcplab) & [Discussion group](https://t.me/quickgcplabchats)

# [QUICK GCP LAB](https://www.youtube.com/@quickgcplab)
