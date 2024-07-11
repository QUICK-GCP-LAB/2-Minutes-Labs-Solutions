# Build and Deploy Machine Learning Solutions with Vertex AI: Challenge Lab || [GSP354](https://www.cloudskillsboost.google/focuses/22019?parent=catalog) ||

## Solution [here](https://youtu.be/5YOvpPtWMnI)

### Task 1: Create a Vertex Notebooks instance

1. Navigate to `Vertex AI` > `Workbench` > `Instances`.

2. Click on the `Create New` button.

3. Fill out the form with the following options:

* Name: `vertex-ai-challenge`
* Region: *Check Lab Instruction*
* Zone: Leave the value as default

1. Click on `Environment`.

2. Select `Use a previous version.` In the Version dropdown, select *`workbench-instances-v20240214 (M117)`*

4. Click `Continue.`

5. Select `e2-standard-4` as the Machine Type.

6. Click `Create.`

### Task 2: Download the challenge notebook


1. Access the `terminal` in your `notebook` and use the following command to clone the repository:

```
git clone https://github.com/QUICK-GCP-LAB/training-data-analyst.git
```

2. Install the required packages for the lab:

```
cd training-data-analyst/quests/vertex-ai/vertex-challenge-lab
pip install -U -r requirements.txt --user
```
3. Go to the enclosing folder: *training-data-analyst/quests/vertex-ai/vertex-challenge-lab*.

4. Open the `notebook file` `vertex-challenge-lab.ipynb`. When asked which kernel to use, select the `TensorFlow 2-11` kernel.

5. In the `Setup` section, define your `PROJECT_ID`, `REGION`, and `GCS_BUCKET` variables.

### For Tasks 3,4,5 & 6 Follow [Video](https://youtu.be/5YOvpPtWMnI) Instructions.

* *Note: This training can take around `30-40` minutes to train and deploy the model.*

### Congratulations 🎉 for Completing the Lab !

##### *You Have Successfully Demonstrated Your Skills And Determination.*

#### *Well done!*

#### Don't Forget to Join the [Telegram Channel](https://t.me/quickgcplab) & [Discussion group](https://t.me/quickgcplabchats)

# [QUICK GCP LAB](https://www.youtube.com/@quickgcplab)
