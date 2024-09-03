# Creating Dynamic Secrets for Google Cloud with Vault || [GSP1007](https://www.cloudskillsboost.google/focuses/32204?parent=catalog) ||

## Solution [here](https://youtu.be/MuMcDSeUmAw)

### Run the following Commands in CloudShell

```
curl -LO raw.githubusercontent.com/QUICK-GCP-LAB/2-Minutes-Labs-Solutions/main/Creating%20Dynamic%20Secrets%20for%20Google%20Cloud%20with%20Vault/gsp1007.sh

sudo chmod +x gsp1007.sh

./gsp1007.sh
```

* Open a new Cloud Shell window

```
export VAULT_ADDR='http://127.0.0.1:8200'
vault operator init
```

* Make sure to copy all the **Unseal keys** and **Initial root token**.

* You need **3** of the **5** keys that were generated.

```
vault operator unseal
```
```
vault login INITIAL_ROOT_TOKEN
```
```
vault secrets enable gcp
```

* Go to `Service Accounts` from [here](https://console.cloud.google.com/iam-admin/serviceaccounts?)

```
ls
```
```
vault write gcp/config \
credentials=@REPLACE-PATH \
 ttl=3600 \
 max_ttl=86400
```
```
cat > bindings.hcl << EOM
resource "buckets/$DEVSHELL_PROJECT_ID" {
  roles = [
    "roles/storage.objectAdmin",
    "roles/storage.legacyBucketReader",
  ]
}
EOM

vault write gcp/roleset/my-token-roleset \
    project="$DEVSHELL_PROJECT_ID" \
    secret_type="access_token"  \
    token_scopes="https://www.googleapis.com/auth/cloud-platform" \
    bindings=@bindings.hcl

vault read gcp/roleset/my-token-roleset/token
```
```
curl \
  'https://storage.googleapis.com/storage/v1/b/REPLACE_PROJECT_ID' \
  --header 'Authorization: Bearer REPLACE_OAUTH2_TOKEN' \
  --header 'Accept: application/json'

curl -X GET \
  -H "Authorization: Bearer REPLACE_OAUTH2_TOKEN" \
  -o "sample.txt" \
  "https://storage.googleapis.com/storage/v1/b/REPLACE_PROJECT_ID/o/sample.txt?alt=media"
```
```
vault write gcp/roleset/my-key-roleset \
    project="$DEVSHELL_PROJECT_ID" \
    secret_type="service_account_key"  \
    bindings=@bindings.hcl

vault read gcp/roleset/my-key-roleset/key
```
```
export S_A=
```
```
vault write gcp/static-account/my-token-account \
    service_account_email="$S_A" \
    secret_type="access_token"  \
    token_scopes="https://www.googleapis.com/auth/cloud-platform" \
    bindings=@bindings.hcl

vault write gcp/static-account/my-key-account \
    service_account_email="$S_A" \
    secret_type="service_account_key"  \
    bindings=@bindings.hcl
```

### Congratulations 🎉 for completing the Lab !

##### *You Have Successfully Demonstrated Your Skills And Determination.*

#### *Well done!*

#### Don't Forget to Join the [Telegram Channel](https://t.me/quickgcplab) & [Discussion group](https://t.me/quickgcplabchats)

# [QUICK GCP LAB](https://www.youtube.com/@quickgcplab)
