# Main Application Server - App + Redis

resource "google_compute_address" "main" {
  name = "${var.prefix}-main-ip"
}

resource "google_compute_instance" "main" {
  name         = "${var.prefix}-main-server"
  machine_type = var.main_server_machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 30  # GB
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.main.id

    access_config {
      nat_ip = google_compute_address.main.address
    }
  }

  metadata = {
    ssh-keys = "ubuntu:${tls_private_key.main.public_key_openssh}"
  }

  tags = ["${var.prefix}-server", "main-server"]

  labels = {
    name        = "${var.prefix}-main-server"
    environment = var.environment
    role        = "application"
  }
}

# Initial setup - Docker installation
resource "null_resource" "main_setup" {
  depends_on = [google_compute_instance.main]

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
      # Install Alloy for local metrics/logs collection
      "sudo mkdir -p /etc/apt/keyrings/",
      "wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | sudo tee /etc/apt/keyrings/grafana.gpg > /dev/null",
      "echo 'deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main' | sudo tee /etc/apt/sources.list.d/grafana.list",
      "sudo apt-get update",
      "sudo apt-get install -y alloy",
      # Create directories
      "mkdir -p /home/ubuntu/{app,redis,configs}",
      "echo 'Main server setup complete' > /home/ubuntu/setup-complete.txt",
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = tls_private_key.main.private_key_pem
      host        = google_compute_address.main.address
    }
  }
}
