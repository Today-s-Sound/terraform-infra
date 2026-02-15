# Main Server Outputs
output "main_server_ip" {
  value       = module.main_server.eip_public_ip
  description = "Main application server public IP"
}

output "main_server_url" {
  value       = "http://${module.main_server.eip_public_ip}"
  description = "Main application server URL"
}

# Monitoring Server Outputs
output "monitoring_server_ip" {
  value       = module.monitoring.public_ip
  description = "Monitoring server public IP"
}

output "monitoring_ssh_tunnel_commands" {
  value = {
    grafana    = "ssh -i ${local.private_key_filename} -L 3000:localhost:3000 ubuntu@${module.monitoring.public_ip}"
    prometheus = "ssh -i ${local.private_key_filename} -L 9090:localhost:9090 ubuntu@${module.monitoring.public_ip}"
    loki       = "ssh -i ${local.private_key_filename} -L 3100:localhost:3100 ubuntu@${module.monitoring.public_ip}"
    alloy      = "ssh -i ${local.private_key_filename} -L 12345:localhost:12345 ubuntu@${module.monitoring.public_ip}"
  }
  description = "SSH tunnel commands for monitoring services"
}

# Load Test Server Outputs
output "loadtest_server_ip" {
  value       = var.enable_loadtest ? module.loadtest[0].public_ip : null
  description = "Load test server public IP (null if disabled)"
}

# RDS Outputs
output "rds_endpoint" {
  value       = module.rds.endpoint
  description = "RDS MySQL endpoint"
}

output "rds_address" {
  value       = module.rds.address
  description = "RDS MySQL hostname"
}

# S3 Outputs
output "s3_bucket_name" {
  value       = module.s3.bucket_name
  description = "S3 bucket name"
}

output "s3_bucket_arn" {
  value       = module.s3.bucket_arn
  description = "S3 bucket ARN"
}

output "s3_logs_bucket_name" {
  value       = module.s3_logs.bucket_name
  description = "S3 logs bucket name"
}

# Route53 Outputs
output "route53_nameservers" {
  value       = module.route53.nameservers
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
      ip   = module.main_server.eip_public_ip
      role = "Spring Boot + Redis"
    }
    monitoring_server = {
      ip   = module.monitoring.public_ip
      role = "Prometheus + Grafana + Loki + Alloy (SSH tunnel)"
    }
    loadtest_server = {
      ip   = var.enable_loadtest ? module.loadtest[0].public_ip : "disabled"
      role = "K6 + Locust + Apache Bench"
    }
  }
  description = "All servers summary"
}
