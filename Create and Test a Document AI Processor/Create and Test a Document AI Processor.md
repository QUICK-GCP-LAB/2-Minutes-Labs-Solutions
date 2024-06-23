# Create and Test a Document AI Processor || [GSP924](https://www.cloudskillsboost.google/focuses/21028?parent=catalog) ||

## Solution [here]()

### Run the following Commands in CloudShell

* Go to `Cloud Document AI API` from [here](https://console.cloud.google.com/marketplace/product/google/documentai.googleapis.com)

* Go to `Document AI` from [here](https://console.cloud.google.com/ai/document-ai?)

```
export ZONE=$(gcloud compute instances list document-ai-dev --format 'csv[no-heading](zone)')
gcloud compute ssh document-ai-dev --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet
```
```
export PROCESSOR_ID=
```

```
curl -LO raw.githubusercontent.com/QUICK-GCP-LAB/2-Minutes-Labs-Solutions/main/Create%20and%20Test%20a%20Document%20AI%20Processor/gsp924.sh

sudo chmod +x gsp924.sh

./gsp924.sh
```

### Congratulations 🎉 for completing the Challenge Lab !

##### *You Have Successfully Demonstrated Your Skills And Determination.*

#### *Well done!*

#### Don't Forget to Join the [Telegram Channel](https://t.me/QuickGcpLab) & [Discussion group](https://t.me/QuickGcpLabChats)

# [QUICK GCP LAB](https://www.youtube.com/@quickgcplab)