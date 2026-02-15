# RDS MySQL

resource "aws_db_subnet_group" "main" {
  name       = "${var.prefix}-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "${var.prefix}-db-subnet-group"
  }
}

resource "aws_db_instance" "main" {
  identifier     = "${var.prefix}-mysql"
  engine         = "mysql"
  engine_version = "8.0"

  instance_class    = var.instance_class
  allocated_storage = 20
  storage_type      = "gp3"

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = var.sg_ids

  skip_final_snapshot       = false
  final_snapshot_identifier = "${var.prefix}-${var.environment}-final-snapshot"

  backup_retention_period = var.environment == "prod" ? 7 : 1
  multi_az                = false

  tags = {
    Name        = "${var.prefix}-mysql"
    Environment = var.environment
  }
}
