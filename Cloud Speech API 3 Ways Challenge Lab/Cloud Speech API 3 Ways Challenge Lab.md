# Cloud Speech API 3 Ways: Challenge Lab || [ARC132](https://www.cloudskillsboost.google/focuses/67215?parent=catalog) ||

## Solution [here]()

### Run the following Commands in CloudShell

```
export ZONE=$(gcloud compute instances list lab-vm --format 'csv[no-heading](zone)')
gcloud compute ssh lab-vm --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet
```
```
API_KEY=
task_2_file_name=""
task_3_request_file=""
task_3_response_file=""
task_4_sentence=""
task_4_file=""
task_5_sentence=""
task_5_file=""
```
```
curl -LO raw.githubusercontent.com/QUICK-GCP-LAB/2-Minutes-Labs-Solutions/main/Cloud%20Speech%20API%203%20Ways%20Challenge%20Lab/arc132.sh

sudo chmod +x arc132.sh

./arc132.sh
```

### Congratulations 🎉 for completing the Challenge Lab !

##### *You Have Successfully Demonstrated Your Skills And Determination.*

#### *Well done!*

#### Don't Forget to Join the [Telegram Channel](https://t.me/QuickGcpLab) & [Discussion group](https://t.me/QuickGcpLabChats)

# [QUICK GCP LAB](https://www.youtube.com/@quickgcplab)