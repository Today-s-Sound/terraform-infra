output "catapp_url" {
  value = "http://${google_compute_address.hashicat.address}"
}

output "instance_ip" {
  value       = google_compute_address.hashicat.address
  description = "The public IP address of the instance (for GitHub Actions)"
}

output "monitoring_urls" {
  value = {
    grafana    = "http://${google_compute_address.hashicat.address}:3000"
    prometheus = "http://${google_compute_address.hashicat.address}:9090"
    loki       = "http://${google_compute_address.hashicat.address}:3100"
    alloy      = "http://${google_compute_address.hashicat.address}:12345"
  }
  description = "Monitoring stack URLs (Grafana, Prometheus, Loki, Alloy)"
}

output "ssh_private_key" {
  value       = tls_private_key.hashicat.private_key_pem
  description = "SSH private key for GitHub Actions (save to GitHub Secrets as GCP_SSH_PRIVATE_KEY)"
  sensitive   = true
}
