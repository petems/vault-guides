variable "billing_account" {
}

variable "org_id" {
}

resource "random_id" "id" {
  byte_length = 1
  prefix      = "vaultguides-gcp-secrets-"
}

resource "google_project" "vault_gcp_secrets_demo" {
  name            = "vault-gcp-secrets-demo"
  project_id      = random_id.id.hex
  billing_account = var.billing_account
  org_id          = var.org_id
}

resource "google_project_services" "vault_gcp_secrets_demo_services" {
  project = google_project.vault_gcp_secrets_demo.project_id

  services = [
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "oslogin.googleapis.com",
    "compute.googleapis.com",
    "serviceusage.googleapis.com",
  ]
}

output "project_id" {
  value = google_project.vault_gcp_secrets_demo.project_id
}
