# Demonstrate GCP Secrets Engine

This guide will demonstrate Vault's GCP Secrets Engine.

Vault will dynamically generate Google Cloud service account keys and OAuth tokens based on IAM policies. This enables users to gain access to Google Cloud resources without needing to create or manage a dedicated service account.

## Background

The project will create the following resources in GCP:

* vault-gcp-iam-demo-[abc] - A project with a random generated name to assosiate all the resources to
* vaultadmin - A Service Account with the iam.serviceAccountKeyAdmin - Vault will use this to check other service account credentials

## Reference Material
https://www.vaultproject.io/docs/secrets/gcp.html
https://www.vaultproject.io/api/secrets/gcp/index.html

## Note
The code in this repository is for reference only. It is meant to illustrate a few of the requirements for using the GCP IAM authentication method.

## Instructions

Install gcloud

With Brew:

```
brew install gcloud
```

Or with the installer:

```
curl https://sdk.cloud.google.com |
exec -l $SHELL
gcloud init
```

Configure authentication:

```
gcloud auth login
gcloud auth application-default login
```

Export your billing and organisation settings:
```
gcloud organizations list
gcloud beta billing accounts list

export TF_VAR_org_id=<Organisation ID>
export TF_VAR_billing_account=<Billing Account ID>
```

Run terraform:

```
terraform init
terraform plan
terraform apply
```

## Configure Vault after installation

Take the VAULT_ADDR listed as an output (eg. `vault_addr_export = Run the following for the Vault configuration: export VAULT_ADDR=http://35.242.177.154:8200`) and initilize:

```
$ export VAULT_ADDR=http://35.242.177.154:8200
$ vault operator init -key-shares=1 -key-threshold=1
Unseal Key 1: hgUddxpCiqgwXwBHuaIJN2TOwYDoL76kR+4by04urzQ=
Initial Root Token: s.2WSW8hAZ0NvjEQCf0mUJMTdF
$ export VAULT_TOKEN='s.2WSW8hAZ0NvjEQCf0mUJMTdF'
$ vault operator unseal hgUddxpCiqgwXwBHuaIJN2TOwYDoL76kR+4by04urzQ=
Key             Value
---             -----
Seal Type       shamir
Initialized     true
Sealed          false
Total Shares    1
Threshold       1
Version         1.1.5
Cluster Name    vault-cluster-bcec9d5f
Cluster ID      5c3759a6-2969-6462-21ed-29441790f73f
HA Enabled      false
```

### Configure Vault GCP Backend and secrets

Configure Vault with Terraform code:

```
cd vault/
terraform plan
terraform apply
cd ..
```

### Generate a token

```
$ vault read gcp/token/project_viewer_token
Key                   Value
---                   -----
expires_at_seconds    1564504641
token                 ya29.c.ElpFAKETOKENFORREADMEkelRLWQpMXA7pemtzRQKlXdnIjfiYCIUVxx5nE-nJipGMaptYmBOBaw4znDBY83PdI5A1RWieHa5zuGa2W1LL9TDeT5Hd_btFUxg8NLFL7_RE
token_ttl             59m59s
```

```
$ export GCP_TOKEN="ya29.c.ElpFAKETOKENFORREADMEkelRLWQpMXA7pemtzRQKlXdnIjfiYCIUVxx5nE-nJipGMaptYmBOBaw4znDBY83PdI5A1RWieHa5zuGa2W1LL9TDeT5Hd_btFUxg8NLFL7_RE"
```

```
$ curl -s -X GET -H "Authorization: Bearer ${GCP_TOKEN}" -H "Content-Type: application/json"  https://www.googleapis.com/compute/v1/projects/vaultguides-gcp-secrets-da/zones/europe-west2-a/instances
{
  "id": "projects/vaultguides-gcp-secrets-da/zones/europe-west2-a/instances",
  "items": [
    {
      "id": "7595863404236889955",
      "creationTimestamp": "2019-07-30T08:26:05.974-07:00",
      "name": "vault-server",
      "tags": {
        "items": [
          "vault-server"
        ],
[...]
```

### Generate a service account

```
$ export GOOGLE_CREDENTIALS=$(vault read -field=private_key_data gcp/key/my-project-viewer | base64 --decode)
$ export SA_EMAIL=$(printf '%s' $GOOGLE_CREDENTIALS | jq -r .client_email)
$ gcloud auth activate-service-account $SA_EMAIL --key-file=<<<$(printf '%s' $GOOGLE_CREDENTIALS)
Activated service account credentials for: [vaultproject-viewer-1564524130@vaultguides-gcp-secrets-da.iam.gserviceaccount.com]
$ gcloud compute instances list --project=$(printf '%s' $GOOGLE_CREDENTIALS | jq -r .project_id)
NAME          ZONE            MACHINE_TYPE   PREEMPTIBLE  INTERNAL_IP  EXTERNAL_IP     STATUS
vault-server  europe-west2-a  n1-standard-1               10.14.1.4     1.2.3.4         RUNNING
```
