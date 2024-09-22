# Process Documents with Python Using the Document AI API || [GSP925](https://www.cloudskillsboost.google/focuses/21026?parent=catalog) ||

## Solution [here]()

### Run the following Commands in CloudShell

```
curl -LO raw.githubusercontent.com/QUICK-GCP-LAB/2-Minutes-Labs-Solutions/refs/heads/main/Process%20Documents%20with%20Python%20Using%20the%20Document%20AI%20API/gsp925.sh

sudo chmod +x gsp925.sh

./gsp925.sh
```

* Go to **Vertex AI** from [here](https://console.cloud.google.com/vertex-ai?)

* Run the following commands in **Jupyter Notebook Terminal**

```
gsutil cp gs://cloud-training/gsp925/*.ipynb .
python -m pip install --upgrade google-cloud-core google-cloud-documentai google-cloud-storage prettytable --user
gsutil cp gs://cloud-training/gsp925/health-intake-form.pdf form.pdf

export PROJECT_ID="$(gcloud config get-value core/project)"
export BUCKET="${PROJECT_ID}"_doc_ai_async
gsutil mb gs://${BUCKET}
gsutil -m cp gs://cloud-training/gsp925/async/*.* gs://${BUCKET}/input
```

### Congratulations 🎉 for completing the Lab !

##### *You Have Successfully Demonstrated Your Skills And Determination.*

#### *Well done!*

#### Don't Forget to Join the [Telegram Channel](https://t.me/quickgcplab) & [Discussion group](https://t.me/quickgcplabchats)

# [QUICK GCP LAB](https://www.youtube.com/@quickgcplab)