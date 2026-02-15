output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_a_id" {
  value = aws_subnet.public_a.id
}

output "public_subnet_b_id" {
  value = aws_subnet.public_b.id
}

output "private_subnet_ids" {
  value = [aws_subnet.private_a.id, aws_subnet.private_b.id]
}

output "sg_main_id" {
  value = aws_security_group.main.id
}

output "sg_monitoring_id" {
  value = aws_security_group.monitoring.id
}

output "sg_loadtest_id" {
  value = aws_security_group.loadtest.id
}

output "sg_rds_id" {
  value = aws_security_group.rds.id
}
