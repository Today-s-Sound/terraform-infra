output "instance_id" {
  value = aws_instance.this.id
}

output "public_ip" {
  value = aws_instance.this.public_ip
}

output "private_ip" {
  value = aws_instance.this.private_ip
}

output "eip_public_ip" {
  value = var.create_eip ? aws_eip.this[0].public_ip : null
}
