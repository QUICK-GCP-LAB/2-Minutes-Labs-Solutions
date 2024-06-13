# Streaming Data to Bigtable || [GSP1055](https://www.cloudskillsboost.google/focuses/58499?locale=es&parent=catalog) ||

## Solution [here]()

### Run the following Commands in CloudShell (`Project-1` Or `NYC Bike Share Project` )

```
export REGION=
```
```
curl -LO raw.githubusercontent.com/QUICK-GCP-LAB/2-Minutes-Labs-Solutions/main/Streaming%20Data%20to%20Bigtable/gsp1055-1.sh

sudo chmod +x gsp1055-1.sh

./gsp1055-1.sh
```

* Go to `BigQuery` from [here](https://console.cloud.google.com/bigquery)

### Run the following Query in `BigQuery` (`Project-1` Or `NYC Bike Share Project` )

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

### Run the following Query in `BigQuery` (`Project-2` Or `NYC Motor Vehicle Collisions Project` )

```
SELECT
  contributing_factor_vehicle_1 AS collision_factor,
  COUNT(*) AS num_collisions
FROM
  `new_york_mv_collisions.nypd_mv_collisions`
WHERE
  contributing_factor_vehicle_1 != "Unspecified"
  AND contributing_factor_vehicle_1 != ""
GROUP BY
  collision_factor
ORDER BY
  num_collisions DESC
LIMIT 10;
```

### Congratulations 🎉 for Completing the Lab !

##### *You Have Successfully Demonstrated Your Skills And Determination.*

#### *Well done!*

#### Don't Forget to Join the [Telegram Channel](https://t.me/QuickGcpLab) & [Discussion group](https://t.me/QuickGcpLabChats)

# [QUICK GCP LAB](https://www.youtube.com/@quickgcplab)