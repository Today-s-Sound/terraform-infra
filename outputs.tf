# Main Server Outputs
output "main_server_ip" {
  value       = aws_eip.main.public_ip
  description = "Main application server public IP"
}

output "main_server_url" {
  value       = "http://${aws_eip.main.public_ip}"
  description = "Main application server URL"
}

# Monitoring Server Outputs
output "monitoring_server_ip" {
  value       = aws_eip.monitoring.public_ip
  description = "Monitoring server public IP"
}

output "monitoring_ssh_tunnel_commands" {
  value = {
    grafana    = "ssh -i ${local.private_key_filename} -L 3000:localhost:3000 ubuntu@${aws_eip.monitoring.public_ip}"
    prometheus = "ssh -i ${local.private_key_filename} -L 9090:localhost:9090 ubuntu@${aws_eip.monitoring.public_ip}"
    loki       = "ssh -i ${local.private_key_filename} -L 3100:localhost:3100 ubuntu@${aws_eip.monitoring.public_ip}"
    alloy      = "ssh -i ${local.private_key_filename} -L 12345:localhost:12345 ubuntu@${aws_eip.monitoring.public_ip}"
  }
  description = "SSH tunnel commands for monitoring services"
}

# Load Test Server Outputs
output "loadtest_server_ip" {
  value       = var.enable_loadtest ? aws_eip.loadtest[0].public_ip : null
  description = "Load test server public IP (null if disabled)"
}

# RDS Outputs
output "rds_endpoint" {
  value       = aws_db_instance.main.endpoint
  description = "RDS PostgreSQL endpoint"
}

output "rds_address" {
  value       = aws_db_instance.main.address
  description = "RDS PostgreSQL hostname"
}

# S3 Outputs
output "s3_bucket_name" {
  value       = aws_s3_bucket.main.bucket
  description = "S3 bucket name"
}

output "s3_bucket_arn" {
  value       = aws_s3_bucket.main.arn
  description = "S3 bucket ARN"
}

# Route53 Outputs
output "route53_nameservers" {
  value       = var.domain_name != "" ? aws_route53_zone.main[0].name_servers : null
  description = "Route53 nameservers (set these at your domain registrar)"
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
      ip   = aws_eip.main.public_ip
      role = "Spring Boot + Redis"
    }
    monitoring_server = {
      ip   = aws_eip.monitoring.public_ip
      role = "Prometheus + Grafana + Loki + Alloy (SSH tunnel)"
    }
    loadtest_server = {
      ip   = var.enable_loadtest ? aws_eip.loadtest[0].public_ip : "disabled"
      role = "K6 + Locust + Apache Bench"
    }
  }
  description = "All servers summary"
}
