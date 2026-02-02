terraform {
  cloud {
    organization = "test0217"
    hostname     = "app.terraform.io" # default

    workspaces {
      name = "terraform-gcp-tfc-workflow"
    }
  }
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_compute_network" "hashicat" {
  name                    = "${var.prefix}-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "hashicat" {
  name          = "${var.prefix}-subnet"
  ip_cidr_range = var.subnet_prefix
  region        = var.region
  network       = google_compute_network.hashicat.id
}

resource "google_compute_firewall" "hashicat_ssh" {
  name    = "${var.prefix}-allow-ssh"
  network = google_compute_network.hashicat.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["${var.prefix}-instance"]
}

resource "google_compute_firewall" "hashicat_http" {
  name    = "${var.prefix}-allow-http"
  network = google_compute_network.hashicat.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["${var.prefix}-instance"]
}

resource "google_compute_firewall" "hashicat_https" {
  name    = "${var.prefix}-allow-https"
  network = google_compute_network.hashicat.name

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["${var.prefix}-instance"]
}

resource "google_compute_firewall" "hashicat_monitoring" {
  name    = "${var.prefix}-allow-monitoring"
  network = google_compute_network.hashicat.name

  allow {
    protocol = "tcp"
    ports    = ["3000", "9090", "3100", "12345"]  # Grafana, Prometheus, Loki, Alloy
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["${var.prefix}-instance"]
}

resource "google_compute_firewall" "hashicat_otlp" {
  name    = "${var.prefix}-allow-otlp"
  network = google_compute_network.hashicat.name

  allow {
    protocol = "tcp"
    ports    = ["4317", "4318"]  # OTLP gRPC, OTLP HTTP
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["${var.prefix}-instance"]
}

resource "google_compute_address" "hashicat" {
  name = "${var.prefix}-static-ip"
}

resource "google_compute_instance" "hashicat" {
  name         = "${var.prefix}-instance"
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.hashicat.id

    access_config {
      nat_ip = google_compute_address.hashicat.address
    }
  }

  metadata = {
    ssh-keys = "ubuntu:${tls_private_key.hashicat.public_key_openssh}"
  }

  tags = ["${var.prefix}-instance"]

  labels = {
    name        = "${var.prefix}-instance"
    environment = var.environment
  }
}

# Initial setup only - installs Docker and basic dependencies
# Application deployment is handled by GitHub Actions
resource "null_resource" "initial_setup" {
  depends_on = [google_compute_instance.hashicat]

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sleep 15",
      "sudo apt-get update",
      # Install Docker
      "sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg",
      "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null",
      "sudo apt-get update",
      "sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin",
      "sudo usermod -aG docker ubuntu",
      "sudo systemctl enable docker",
      "sudo systemctl start docker",
      # Create directories for GitHub Actions to use
      "mkdir -p /home/ubuntu/{scripts,docker,configs}",
      "echo 'Docker installation complete. Ready for GitHub Actions deployment.' > /home/ubuntu/setup-complete.txt",
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = tls_private_key.hashicat.private_key_pem
      host        = google_compute_address.hashicat.address
    }
  }
}

resource "tls_private_key" "hashicat" {
  algorithm = "RSA"
}

locals {
  private_key_filename = "${var.prefix}-ssh-key.pem"
}
