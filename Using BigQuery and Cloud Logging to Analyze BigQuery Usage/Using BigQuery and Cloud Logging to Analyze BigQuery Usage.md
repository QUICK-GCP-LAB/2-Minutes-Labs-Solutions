# Using BigQuery and Cloud Logging to Analyze BigQuery Usage || [GSP617](https://www.cloudskillsboost.google/focuses/6100?parent=catalog) ||

## Solution [here]()

### Run the following Commands in CloudShell

```
curl -LO raw.githubusercontent.com/QUICK-GCP-LAB/2-Minutes-Labs-Solutions/main/Using%20BigQuery%20and%20Cloud%20Logging%20to%20Analyze%20BigQuery%20Usage/gsp617-1.sh

sudo chmod +x gsp617-1.sh

./gsp617-1.sh
```

1. Click here to go to [Logs Explorer](https://console.cloud.google.com/logs/query?_ga=2.234090203.434727323.1711191791-1746730280.1711191644)

2. In Resource, select `BigQuery`, then `click Apply`.

3. Scroll back up to the header of the entry, click on `jobcompleted` and choose Show matching entries.

4. Now, click `Run query` button in the top right.

* Sink name: `JobComplete` and click NEXT.
* Select sink service: `BigQuery dataset`.
* Select Bigquery dataset (Destination): `bq_logs` (The dataset you setup previously)
* Leave the rest of the options at the default settings.
* Click CREATE SINK*.

### Run again the following Commands in CloudShell

```
curl -LO raw.githubusercontent.com/QUICK-GCP-LAB/2-Minutes-Labs-Solutions/main/Using%20BigQuery%20and%20Cloud%20Logging%20to%20Analyze%20BigQuery%20Usage/gsp617-2.sh

sudo chmod +x gsp617-2.sh

./gsp617-2.sh
```

### Congratulations 🎉 for completing the Challenge Lab !

##### *You Have Successfully Demonstrated Your Skills And Determination.*

#### *Well done!*

#### Don't Forget to Join the [Telegram Channel](https://t.me/QuickGcpLab) & [Discussion group](https://t.me/QuickGcpLabChats)

# [QUICK GCP LAB](https://www.youtube.com/@quickgcplab)