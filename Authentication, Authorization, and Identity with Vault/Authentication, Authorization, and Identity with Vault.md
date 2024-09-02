# Authentication, Authorization, and Identity with Vault || [GSP1005](https://www.cloudskillsboost.google/focuses/32203?parent=catalog) ||

## Solution [here]()

### Run the following Commands in CloudShell

```
curl -LO raw.githubusercontent.com/QUICK-GCP-LAB/2-Minutes-Labs-Solutions/main/Authentication%2C%20Authorization%2C%20and%20Identity%20with%20Vault/gsp1005-1.sh

sudo chmod +x gsp1005-1.sh

./gsp1005-1.sh
```
```
export VAULT_TOKEN=""
```
```
curl -LO raw.githubusercontent.com/QUICK-GCP-LAB/2-Minutes-Labs-Solutions/main/Authentication%2C%20Authorization%2C%20and%20Identity%20with%20Vault/gsp1005-2.sh

sudo chmod +x gsp1005-2.sh

./gsp1005-2.sh
```
```
vault write auth/approle/login role_id="REPLACE-ROLE-ID" secret_id="REPLACE-SECRET-ID"
```
```
export APP_TOKEN=""
```
```
curl -LO raw.githubusercontent.com/QUICK-GCP-LAB/2-Minutes-Labs-Solutions/main/Authentication%2C%20Authorization%2C%20and%20Identity%20with%20Vault/gsp1005-3.sh

sudo chmod +x gsp1005-3.sh

./gsp1005-3.sh
```

### Congratulations 🎉 for completing the Lab !

##### *You Have Successfully Demonstrated Your Skills And Determination.*

#### *Well done!*

#### Don't Forget to Join the [Telegram Channel](https://t.me/quickgcplab) & [Discussion group](https://t.me/quickgcplabchats)

# [QUICK GCP LAB](https://www.youtube.com/@quickgcplab)