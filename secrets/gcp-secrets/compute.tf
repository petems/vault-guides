data "http" "current_ip" {
  url = "http://ipv4.icanhazip.com/"
}

resource "google_compute_network" "vault_gcp_secrets_demo_network" {
  project    = google_project.vault_gcp_secrets_demo.project_id
  name       = "vault-gcp-demo"
  depends_on = [google_project_services.vault_gcp_secrets_demo_services]
}

resource "google_compute_firewall" "allow_vault_access" {
  project    = google_project.vault_gcp_secrets_demo.project_id
  name       = "allow-vault-access"
  network    = google_compute_network.vault_gcp_secrets_demo_network.self_link
  depends_on = [
    google_project_services.vault_gcp_secrets_demo_services,
  ]
  allow {
    protocol = "icmp"
  }
  allow {
    protocol = "tcp"
    ports    = ["22", "8200"]
  }
  source_ranges = [
    "${chomp(data.http.current_ip.body)}/32",
  ]
  target_tags = ["vault-server"]
}

resource "google_compute_instance" "vault_server" {
  name         = "vault-server"
  machine_type = "n1-standard-1"
  zone         = "europe-west2-a"
  project      = google_project.vault_gcp_secrets_demo.project_id
  tags         = ["vault-server"]
  depends_on   = [google_project_services.vault_gcp_secrets_demo_services]
  network_interface {
    network = google_compute_network.vault_gcp_secrets_demo_network.self_link
    access_config { # Public-facing IP
    }
  }
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }
  metadata_startup_script = file("./scripts/install_vault.sh")
  service_account {
    email  = "${google_service_account.vaultadmin.email}"
    scopes = ["cloud-platform"]
  }
}

output "vault_server_instance_id" {
  value = google_compute_instance.vault_server.self_link
}

output "vault_addr_export" {
  value = "Run the following for the Vault configuration: export VAULT_ADDR=http://${google_compute_instance.vault_server.network_interface[0].access_config[0].nat_ip}:8200"
}
