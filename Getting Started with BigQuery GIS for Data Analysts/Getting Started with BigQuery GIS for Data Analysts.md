# Getting Started with BigQuery GIS for Data Analysts || [GSP866](https://www.cloudskillsboost.google/focuses/17817?parent=catalog) ||

## 🔑 Solution [here](https://youtu.be/zQpg_ZPsASs)

### ⚙️ Execute the Following Commands in Cloud Shell

```
curl -LO raw.githubusercontent.com/QUICK-GCP-LAB/2-Minutes-Labs-Solutions/refs/heads/main/Getting%20Started%20with%20BigQuery%20GIS%20for%20Data%20Analysts/gsp866.sh

sudo chmod +x *.sh

./*.sh
```

* In the query window, enter the following standard SQL query:

```
-- Finds Citi Bike stations with > 30 bikes
SELECT
  ST_GeogPoint(longitude, latitude)  AS WKT,
  num_bikes_available
FROM
  `bigquery-public-data.new_york.citibike_stations`
WHERE num_bikes_available > 30
```

# 🎉 Woohoo! You Did It! 🎉

Your hard work and determination paid off! 💻
You've successfully completed the lab. **Way to go!** 🚀

### 💬 Stay Connected with Our Community!
👉 Join the conversation and never miss an update:
📢 [Telegram Channel](https://t.me/quickgcplab)
👥 [Discussion Group](https://t.me/quickgcplabchats)

# [QUICK GCP LAB](https://www.youtube.com/@quickgcplab)
