# Monitoring in Google Cloud: Challenge Lab || [ARC115](https://www.cloudskillsboost.google/focuses/63855?parent=catalog) ||

## Solution [here](https://youtu.be/cZJn_C_Ry4w)

### Run the following Commands in CloudShell

```
curl -LO raw.githubusercontent.com/QUICK-GCP-LAB/2-Minutes-Labs-Solutions/main/Monitoring%20in%20Google%20Cloud%20Challenge%20Lab/arc115.sh

sudo chmod +x arc115.sh

./arc115.sh
```

### NOW FOLLOW [VIDEO'S](https://youtu.be/bJmehGefeek) INSTRUCTIONS.

* Go to `Create Uptime Check` from [here](https://console.cloud.google.com/monitoring/uptime/create?)

1. For Title: enter `quickgcplab`

* Go to `Dashboards` from [here](https://console.cloud.google.com/monitoring/dashboards?)

1. Add the first line chart that has a Resource metric filter, `CPU load (1m)`, for the VM.

2. Add a second line chart that has a Resource metric filter, `Requests`, for Apache Web Server.

* Go to `Create log-based metric` from [here](https://console.cloud.google.com/logs/metrics/edit?)

1. * For Log-based metric name: enter `quickgcplab`

2. Paste The Following in `Build filter` & Replace PROJECT_ID
```
resource.type="gce_instance"
logName="projects/PROJECT_ID/logs/apache-access"
textPayload:"200"
```

3. Paste The Following in `Regular Expression` field:
```
execution took (\d+)
```

### Congratulations 🎉 for completing the Lab !

##### *You Have Successfully Demonstrated Your Skills And Determination.*

#### *Well done!*

#### Don't Forget to Join the [Telegram Channel](https://t.me/quickgcplab) & [Discussion group](https://t.me/quickgcplabchats)

# [QUICK GCP LAB](https://www.youtube.com/@quickgcplab)
