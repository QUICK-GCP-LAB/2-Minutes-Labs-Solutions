# Exploring Dataset Metadata Between Projects with Data Catalog || [GSP789](https://www.cloudskillsboost.google/focuses/11034?parent=catalog) ||

## Solution [here](https://youtu.be/sya_vncb984)

### Run the following Commands in CloudShell ( `Project-1` Or `NYC Bike Share Project` )

```
export PROJECT_ID_2=
export REGION=
```
```
curl -LO raw.githubusercontent.com/QUICK-GCP-LAB/2-Minutes-Labs-Solutions/main/Exploring%20Dataset%20Metadata%20Between%20Projects%20with%20Data%20Catalog/gsp789.sh

sudo chmod +x gsp789.sh

./gsp789.sh
```

### Run the following Query in `BigQuery` ( `Project-1` Or `NYC Bike Share Project` )

```
WITH unknown AS (
  SELECT
    gender,
    CONCAT(start_station_name, " to ", end_station_name) AS route,
    COUNT(*) AS num_trips
  FROM
    `new_york_citibike.citibike_trips`
  WHERE gender = 'unknown'
  GROUP BY
    gender,
    start_station_name,
    end_station_name
  ORDER BY
    num_trips DESC
  LIMIT 5
)

, female AS (
  SELECT
    gender,
    CONCAT(start_station_name, " to ", end_station_name) AS route,
    COUNT(*) AS num_trips
  FROM
    `new_york_citibike.citibike_trips`
  WHERE gender = 'female'
  GROUP BY
    gender,
    start_station_name,
    end_station_name
  ORDER BY
    num_trips DESC
  LIMIT 5
)

, male AS (
  SELECT
    gender,
    CONCAT(start_station_name, " to ", end_station_name) AS route,
    COUNT(*) AS num_trips
  FROM
    `bigquery-public-data.new_york_citibike.citibike_trips`
  WHERE gender = 'male'
  GROUP BY
    gender,
    start_station_name,
    end_station_name
  ORDER BY
    num_trips DESC
  LIMIT 5
)

SELECT * FROM unknown
UNION ALL
SELECT * FROM female
UNION ALL
SELECT * FROM male;
```


### Congratulations 🎉 for Completing the Lab !

##### *You Have Successfully Demonstrated Your Skills And Determination.*

#### *Well done!*

#### Don't Forget to Join the [Telegram Channel](https://t.me/quickgcplab) & [Discussion group](https://t.me/quickgcplabchats)

# [QUICK GCP LAB](https://www.youtube.com/@quickgcplab)
