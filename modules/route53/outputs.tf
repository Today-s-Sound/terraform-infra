output "nameservers" {
  value = var.domain_name != "" ? aws_route53_zone.main[0].name_servers : null
}
