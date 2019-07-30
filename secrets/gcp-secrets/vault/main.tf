provider "vault" {
  version = ">= 1.3.1"
}

data "terraform_remote_state" "gcp_project_state" {
  backend = "local"
  config = {
    path = "${path.module}/../terraform.tfstate"
  }
}

resource "vault_gcp_secret_backend" "gcp" {
}

resource "vault_gcp_secret_roleset" "token" {
  backend      = vault_gcp_secret_backend.gcp.path
  roleset      = "project_viewer_token"
  secret_type  = "access_token"
  project      = data.terraform_remote_state.gcp_project_state.outputs.project_id
  token_scopes = ["https://www.googleapis.com/auth/cloud-platform"]

  binding {
    resource = "//cloudresourcemanager.googleapis.com/projects/${data.terraform_remote_state.gcp_project_state.outputs.project_id}"

    roles = [
      "roles/viewer",
    ]
  }
}

resource "vault_gcp_secret_roleset" "service_account" {
  backend      = vault_gcp_secret_backend.gcp.path
  roleset      = "project_viewer_account"
  secret_type  = "service_account_key"
  project      = data.terraform_remote_state.gcp_project_state.outputs.project_id

  binding {
    resource = "//cloudresourcemanager.googleapis.com/projects/${data.terraform_remote_state.gcp_project_state.outputs.project_id}"

    roles = [
      "roles/viewer",
    ]
  }
}
