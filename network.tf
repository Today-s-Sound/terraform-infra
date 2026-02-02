# Network resources shared across all servers

resource "google_compute_network" "main" {
  name                    = "${var.prefix}-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "main" {
  name          = "${var.prefix}-subnet"
  ip_cidr_range = var.subnet_prefix
  region        = var.region
  network       = google_compute_network.main.id
}

# Firewall rules
resource "google_compute_firewall" "ssh" {
  name    = "${var.prefix}-allow-ssh"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["${var.prefix}-server"]
}

resource "google_compute_firewall" "http" {
  name    = "${var.prefix}-allow-http"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["${var.prefix}-server"]
}

resource "google_compute_firewall" "monitoring" {
  name    = "${var.prefix}-allow-monitoring"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["3000", "9090", "3100", "12345"]  # Grafana, Prometheus, Loki, Alloy
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["monitoring-server"]
}

resource "google_compute_firewall" "redis" {
  name    = "${var.prefix}-allow-redis"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["6379"]
  }

  source_ranges = [var.subnet_prefix]  # Internal only
  target_tags   = ["main-server"]
}

resource "google_compute_firewall" "app" {
  name    = "${var.prefix}-allow-app"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["3000", "8080"]  # Adjust to your app ports
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["main-server"]
}
