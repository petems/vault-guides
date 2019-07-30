locals {
  iam_admin_roles = [
    "roles/iam.serviceAccountAdmin",
    "roles/iam.serviceAccountKeyAdmin",
  ]
}

resource "google_project_iam_custom_role" "vault_project_policy_admin" {
  project      = google_project.vault_gcp_secrets_demo.project_id
  role_id     = "vaultProjectPolicyAdmin"
  title       = "vaultProjectPolicyAdmin"
  description = "Role for Vault Guide backend to manage project IAM policy"
  permissions = [
    "resourcemanager.projects.getIamPolicy",
    "resourcemanager.projects.setIamPolicy",
  ]
}

resource "google_project_iam_custom_role" "inventory" {
  project = google_project.vault_gcp_secrets_demo.project_id
  role_id = "inventory"
  title   = "Inventory"

  permissions = [
    "compute.zones.list",
    "compute.instances.list",
    "compute.firewalls.list",
  ]
}

resource "google_service_account" "vaultadmin" {
  project      = google_project.vault_gcp_secrets_demo.project_id
  account_id   = "vaultadmin"
  display_name = "Vault Admin for IAM"
}

resource "google_project_iam_member" "server_roles" {
  count   = length(local.iam_admin_roles)
  role    = local.iam_admin_roles[count.index]
  project = google_project.vault_gcp_secrets_demo.project_id
  member  = "serviceAccount:${google_service_account.vaultadmin.email}"
}

resource "google_project_iam_member" "vault_project_policy" {
  project = google_project.vault_gcp_secrets_demo.project_id
  role    = "projects/${google_project.vault_gcp_secrets_demo.project_id}/roles/${google_project_iam_custom_role.vault_project_policy_admin.role_id}"

  member = "serviceAccount:${google_service_account.vaultadmin.email}"
}

resource "google_project_iam_member" "inventory_policy" {
  project = google_project.vault_gcp_secrets_demo.project_id
  role    = "projects/${google_project.vault_gcp_secrets_demo.project_id}/roles/${google_project_iam_custom_role.inventory.role_id}"

  member = "serviceAccount:${google_service_account.vaultadmin.email}"
}
