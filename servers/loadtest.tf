# Load Test Server - K6, Locust, etc.

resource "google_compute_address" "loadtest" {
  name = "${var.prefix}-loadtest-ip"
}

resource "google_compute_instance" "loadtest" {
  name         = "${var.prefix}-loadtest-server"
  machine_type = "e2-medium"  # More CPU for load testing
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 20  # GB
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.main.id

    access_config {
      nat_ip = google_compute_address.loadtest.address
    }
  }

  metadata = {
    ssh-keys = "ubuntu:${tls_private_key.main.public_key_openssh}"
  }

  tags = ["${var.prefix}-server", "loadtest-server"]

  labels = {
    name        = "${var.prefix}-loadtest-server"
    environment = var.environment
    role        = "loadtest"
  }
}

# Initial setup - Install load testing tools
resource "null_resource" "loadtest_setup" {
  depends_on = [google_compute_instance.loadtest]

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update && sleep 15 && sudo apt-get update",
      # Install K6
      "sudo gpg -k",
      "sudo gpg --no-default-keyring --keyring /usr/share/keyrings/k6-archive-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69",
      "echo 'deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main' | sudo tee /etc/apt/sources.list.d/k6.list",
      "sudo apt-get update",
      "sudo apt-get install -y k6",
      # Install Python and pip for Locust
      "sudo apt-get install -y python3 python3-pip",
      "pip3 install locust",
      # Install Apache Bench
      "sudo apt-get install -y apache2-utils",
      # Create directories
      "mkdir -p /home/ubuntu/{k6-scripts,locust-scripts,results}",
      "echo 'Load test server setup complete' > /home/ubuntu/setup-complete.txt",
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = tls_private_key.main.private_key_pem
      host        = google_compute_address.loadtest.address
    }
  }
}
