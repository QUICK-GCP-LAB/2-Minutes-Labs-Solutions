# Building Demand Forecasting with BigQuery ML || [GSP852](https://www.cloudskillsboost.google/focuses/16547?parent=catalog) ||

## Solution [here](https://youtu.be/pu56M19UBZk)

### Run the following Commands in CloudShell

```
curl -LO raw.githubusercontent.com/QUICK-GCP-LAB/2-Minutes-Labs-Solutions/main/Building%20Demand%20Forecasting%20with%20BigQuery%20ML/gsp852-1.sh

sudo chmod +x gsp852-1.sh

./gsp852-1.sh
```

### Create the table

```
SELECT
 DATE(starttime) AS trip_date,
 start_station_id,
 COUNT(*) AS num_trips
FROM
 `bigquery-public-data.new_york_citibike.citibike_trips`
WHERE
 starttime BETWEEN DATE('2014-01-01') AND ('2016-01-01')
 AND start_station_id IN (521,435,497,293,519)
GROUP BY
 start_station_id,
 trip_date
```

* Select `SAVE RESULTS` .

* In the dropdown menu, select `BigQuery Table`.

* For Dataset select `bqmlforecast`.

* Add a Table name `training_data` .

* Click *EXPORT*.

### Run again the following Commands in CloudShell

```
curl -LO raw.githubusercontent.com/QUICK-GCP-LAB/2-Minutes-Labs-Solutions/main/Building%20Demand%20Forecasting%20with%20BigQuery%20ML/gsp852-2.sh

sudo chmod +x gsp852-2.sh

./gsp852-2.sh
```

### Congratulations 🎉 for completing the Lab !

##### *You Have Successfully Demonstrated Your Skills And Determination.*

#### *Well done!*

#### Don't Forget to Join the [Telegram Channel](https://t.me/quickgcplab) & [Discussion group](https://t.me/quickgcplabchats)

# [QUICK GCP LAB](https://www.youtube.com/@quickgcplab)
