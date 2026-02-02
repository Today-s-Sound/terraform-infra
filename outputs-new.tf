# Main Server Outputs
output "main_server_ip" {
  value       = google_compute_address.main.address
  description = "Main application server public IP"
}

output "main_server_url" {
  value       = "http://${google_compute_address.main.address}"
  description = "Main application server URL"
}

# Monitoring Server Outputs
output "monitoring_server_ip" {
  value       = google_compute_address.monitoring.address
  description = "Monitoring server public IP"
}

output "monitoring_urls" {
  value = {
    grafana    = "http://${google_compute_address.monitoring.address}:3000"
    prometheus = "http://${google_compute_address.monitoring.address}:9090"
    loki       = "http://${google_compute_address.monitoring.address}:3100"
    alloy      = "http://${google_compute_address.monitoring.address}:12345"
  }
  description = "Monitoring stack URLs"
}

# Load Test Server Outputs
output "loadtest_server_ip" {
  value       = google_compute_address.loadtest.address
  description = "Load test server public IP"
}

# SSH Key
output "ssh_private_key" {
  value       = tls_private_key.main.private_key_pem
  description = "SSH private key for all servers (save to GitHub Secrets)"
  sensitive   = true
}

# Summary
output "servers_summary" {
  value = {
    main_server = {
      ip   = google_compute_address.main.address
      role = "Application + Redis"
    }
    monitoring_server = {
      ip   = google_compute_address.monitoring.address
      role = "Prometheus + Grafana + Loki + Alloy"
    }
    loadtest_server = {
      ip   = google_compute_address.loadtest.address
      role = "K6 + Locust + Apache Bench"
    }
  }
  description = "All servers summary"
}
