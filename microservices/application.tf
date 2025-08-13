terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.0"
    }
  }
}

provider "google" {
  project = "sharp-harbor-466005-p5"
  region  = "us-central1"
}

# Backend VPC in custom mode (no auto subnet)
resource "google_compute_network" "backend_vpc" {
  name                    = "backend-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "backend_subnet" {
  name          = "backend-subnet"
  ip_cidr_range = "10.169.0.0/20"
  region        = "us-central1"
  network       = google_compute_network.backend_vpc.id
}

# Frontend VPC 
resource "google_compute_network" "frontend_vpc" {
  name                    = "frontend-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "frontend_subnet" {
  name          = "frontend-subnet"
  ip_cidr_range = "10.168.0.0/20"
  region        = "us-central1"
  network       = google_compute_network.frontend_vpc.id
}

# VPC Peering (bi-directional)
resource "google_compute_network_peering" "frontend_to_backend" {
  name               = "frontend-to-backend"
  network            = google_compute_network.frontend_vpc.self_link
  peer_network       = google_compute_network.backend_vpc.self_link

}

resource "google_compute_network_peering" "backend_to_frontend" {
  name               = "backend-to-frontend"
  network            = google_compute_network.backend_vpc.self_link
  peer_network       = google_compute_network.frontend_vpc.self_link
 
}

# Backend VPC Access Connector for Cloud Run
resource "google_vpc_access_connector" "backend_connector" {
  name          = "backend-vpc-connector"
  region        = "us-central1"
  network       = google_compute_network.backend_vpc.self_link
  ip_cidr_range = "10.10.0.0/28"  # Unique and non-overlapping

  min_instances = 2
  max_instances = 3
  machine_type  = "e2-micro"
}
# Frontend VPC Access Connector for Cloud Run
resource "google_vpc_access_connector" "frontendd_connector" {
  name     = "frontend-vpc-connector"
  region   = "us-central1"
  network  = google_compute_network.frontend_vpc.self_link
  ip_cidr_range = "10.8.0.0/28"  # Adjust the IP range as needed
  min_instances = 2
  max_instances =3
  machine_type ="e2-micro"
}


# Cloud Run backend service using the backend VPC Access Connector
resource "google_cloud_run_v2_service" "backend_application" {
  name     = "cloudrun-backend"
  location = "us-central1"
  ingress  = "INGRESS_TRAFFIC_INTERNAL_ONLY"  # Only allow internal traffic (from frontend)
  deletion_protection = false

  template {
    containers {
      image = "us-central1-docker.pkg.dev/sharp-harbor-466005-p5/repo/backend-app:latest"
    }

    vpc_access {
      connector = google_vpc_access_connector.backend_connector.id
      egress    = "ALL_TRAFFIC"
    }
  }
}
#
resource "google_cloud_run_v2_service" "frontend_application" {
  name     = "cloudrun-frontend"
  location = "us-central1"
  ingress  = "INGRESS_TRAFFIC_ALL"  # This allows public access to the service
  deletion_protection = false

  template {
    containers {
      image = "us-central1-docker.pkg.dev/sharp-harbor-466005-p5/repo/frontend-app:latest"
    }

    vpc_access {
      connector = google_vpc_access_connector.frontendd_connector.id
      egress    = "ALL_TRAFFIC"
    }
     service_account = google_service_account.frontend_to_backend_serviceaccount.email
  }
}
resource "google_service_account" "frontend_to_backend_serviceaccount" {
  account_id   = "front-to-back-sa"
  display_name = "Frontend to Backend Service Account"
}
resource "google_project_iam_member" "frontend_invoke_backend" {
   project = "sharp-harbor-466005-p5"
    role    = "roles/run.invoker"
    member="serviceAccount:${google_service_account.frontend_to_backend_serviceaccount.email}"

}
resource "google_cloud_run_service_iam_member" "frontend_public" {
  location    = "us-central1"
  project     = "sharp-harbor-466005-p5"
  service     = google_cloud_run_v2_service.frontend_application.name
  role        = "roles/run.invoker"
  member      = "allUsers"
}

# Allow ingress from frontend subnet to backend service port (e.g., 5000)
resource "google_compute_firewall" "allow_frontend_to_backend" {
  name    = "allow-frontend-to-backend"
  network = google_compute_network.backend_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["5000"]
  }

  source_ranges = [google_compute_subnetwork.frontend_subnet.ip_cidr_range]
  direction     = "INGRESS"
  priority      = 1000
}

# Deny all other ingress to backend subnet
resource "google_compute_firewall" "deny_all_to_backend" {
  name    = "deny-all-to-backend"
  network = google_compute_network.backend_vpc.name

  deny {
    protocol = "all"
  }

  direction     = "INGRESS"
  priority      = 2000
  source_ranges = ["0.0.0.0/0"]
}
output "frontend_url" {
  value = google_cloud_run_v2_service.frontend_application.uri
  description = "The public URL of the frontend Cloud Run service"
}