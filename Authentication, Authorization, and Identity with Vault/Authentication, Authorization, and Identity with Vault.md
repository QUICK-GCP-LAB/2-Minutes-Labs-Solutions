# Authentication, Authorization, and Identity with Vault || [GSP1005](https://www.cloudskillsboost.google/focuses/32203?parent=catalog) ||

## Solution [here](https://youtu.be/wyHw7Gv897g)

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
export VAULT_ADDR='http://127.0.0.1:8200'

vault status

vault kv put secret/mysql/webapp db_name="users" username="admin" password="passw0rd"

vault auth enable approle

vault policy write jenkins -<<EOF
# Read-only permission on secrets stored at 'secret/data/mysql/webapp'
path "secret/data/mysql/webapp" {
  capabilities = [ "read" ]
}
EOF

vault write auth/approle/role/jenkins token_policies="jenkins" \
    token_ttl=1h token_max_ttl=4h

vault read auth/approle/role/Jenkins

vault read auth/approle/role/jenkins/role-id

vault write -force auth/approle/role/jenkins/secret-id
```
```
vault write auth/approle/login role_id="REPLACE-ROLE-ID" secret_id="REPLACE-SECRET-ID"
```
```
export APP_TOKEN=""
```
```
curl -LO raw.githubusercontent.com/QUICK-GCP-LAB/2-Minutes-Labs-Solutions/main/Authentication%2C%20Authorization%2C%20and%20Identity%20with%20Vault/gsp1005-2.sh

sudo chmod +x gsp1005-2.sh

./gsp1005-2.sh
```

### Congratulations 🎉 for completing the Lab !

##### *You Have Successfully Demonstrated Your Skills And Determination.*

#### *Well done!*

#### Don't Forget to Join the [Telegram Channel](https://t.me/quickgcplab) & [Discussion group](https://t.me/quickgcplabchats)

# [QUICK GCP LAB](https://www.youtube.com/@quickgcplab)
