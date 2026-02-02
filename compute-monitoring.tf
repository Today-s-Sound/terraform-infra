# Monitoring Server - Prometheus, Grafana, Loki, Alloy

resource "google_compute_address" "monitoring" {
  name = "${var.prefix}-monitoring-ip"
}

resource "google_compute_instance" "monitoring" {
  name         = "${var.prefix}-monitoring-server"
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 50  # GB - for logs and metrics storage
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.main.id

    access_config {
      nat_ip = google_compute_address.monitoring.address
    }
  }

  metadata = {
    ssh-keys = "ubuntu:${tls_private_key.main.public_key_openssh}"
  }

  tags = ["${var.prefix}-server", "monitoring-server"]

  labels = {
    name        = "${var.prefix}-monitoring-server"
    environment = var.environment
    role        = "monitoring"
  }
}

# Initial setup - Docker installation
resource "null_resource" "monitoring_setup" {
  depends_on = [google_compute_instance.monitoring]

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update && sleep 15 && sudo apt-get update",
      # Install Docker
      "sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg",
      "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null",
      "sudo apt-get update",
      "sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin",
      "sudo usermod -aG docker ubuntu",
      "sudo systemctl enable docker && sudo systemctl start docker",
      # Create directories
      "mkdir -p /home/ubuntu/{scripts,docker,configs}",
      "echo 'Monitoring server setup complete' > /home/ubuntu/setup-complete.txt",
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = tls_private_key.main.private_key_pem
      host        = google_compute_address.monitoring.address
    }
  }
}
