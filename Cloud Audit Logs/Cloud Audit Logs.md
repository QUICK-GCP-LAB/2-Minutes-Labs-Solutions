# [Cloud Audit Logs](https://www.cloudskillsboost.google/paths/15/course_templates/99/labs/432519?)

## Solution [here](https://youtu.be/IZatdzjmncM)

1. Got `Audit Logs` from [here](https://console.cloud.google.com/iam-admin/audit)

2. Use `Filter` to locate `Google Cloud Storage`.

3. Then `check the box` next to it.

4. Select `Admin Read`, `Data Read` and `Data Write`, and then click `SAVE`.

### Run the following Commands in CloudShell

```
export ZONE=
```
```
curl -LO raw.githubusercontent.com/QUICK-GCP-LAB/2-Minutes-Labs-Solutions/main/Cloud%20Audit%20Logs/Audit-Logs.sh

sudo chmod +x Audit-Logs.sh

./Audit-Logs.sh
```

1. Go to `Logs Explorer` from [here](https://console.cloud.google.com/logs/query)

2. Click the `Log name` dropdown and use the filter to locate the `activity` log under `CLOUD AUDIT` section and `Apply` it to the query.

3. Press the `Run query` button.

4. Delete the existing query and use `Log Name` to view the `data_access` logs.

5. Press the `Run query` button.


### Congratulations 🎉 for Completing the Lab !

##### *You Have Successfully Demonstrated Your Skills And Determination.*

#### *Well done!*

#### Don't Forget to Join the [Telegram Channel](https://t.me/quickgcplab) & [Discussion group](https://t.me/quickgcplabchats)

# [QUICK GCP LAB](https://www.youtube.com/@quickgcplab)
