# Cloud Speech API 3 Ways: Challenge Lab || [ARC132](https://www.cloudskillsboost.google/focuses/67215?parent=catalog) ||

## Solution [here](https://youtu.be/eQIWNzs-0NA)

### Run the following Commands in CloudShell

```
export ZONE=$(gcloud compute instances list lab-vm --format 'csv[no-heading](zone)')
gcloud compute ssh lab-vm --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet
```

* Go to `Credentials` from [here](https://console.cloud.google.com/apis/credentials)

```
export API_KEY=
export task_2_file_name=""
export task_3_request_file=""
export task_3_response_file=""
export task_4_sentence=""
export task_4_file=""
export task_5_sentence=""
export task_5_file=""
```
```
curl -LO raw.githubusercontent.com/QUICK-GCP-LAB/2-Minutes-Labs-Solutions/main/Cloud%20Speech%20API%203%20Ways%20Challenge%20Lab/arc132.sh

sudo chmod +x arc132.sh

./arc132.sh
```

### Congratulations 🎉 for completing the Lab !

##### *You Have Successfully Demonstrated Your Skills And Determination.*

#### *Well done!*

#### Don't Forget to Join the [Telegram Channel](https://t.me/quickgcplab) & [Discussion group](https://t.me/quickgcplabchats)

# [QUICK GCP LAB](https://www.youtube.com/@quickgcplab)
