terraform {
  cloud {
    organization = "todaysound"
    hostname     = "app.terraform.io"

    workspaces {
      name = "terraform-aws-tfc-workflow"
    }
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# SSH Key for all servers
resource "tls_private_key" "main" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "main" {
  key_name   = "${var.prefix}-key"
  public_key = tls_private_key.main.public_key_openssh
}

# Ubuntu 22.04 AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  private_key_filename = "${var.prefix}-ssh-key.pem"
}

# --- Modules ---

module "network" {
  source = "./modules/network"

  prefix           = var.prefix
  environment      = var.environment
  region           = var.region
  allowed_ssh_cidrs = var.allowed_ssh_cidrs
}

module "s3" {
  source = "./modules/s3"

  bucket_name       = var.s3_bucket_name
  environment       = var.environment
  enable_versioning = true
  enable_cors       = true
}

module "s3_logs" {
  source = "./modules/s3"

  bucket_name              = var.s3_logs_bucket_name
  environment              = var.environment
  enable_versioning        = false
  enable_cors              = false
  enable_lifecycle         = true
  lifecycle_expiration_days = 90
}

module "iam" {
  source = "./modules/iam"

  prefix         = var.prefix
  environment    = var.environment
  s3_bucket_arns = [module.s3.bucket_arn, module.s3_logs.bucket_arn]
}

module "monitoring" {
  source = "./modules/compute"

  ami_id               = data.aws_ami.ubuntu.id
  instance_type        = var.monitoring_instance_type
  key_name             = aws_key_pair.main.key_name
  subnet_id            = module.network.public_subnet_a_id
  sg_ids               = [module.network.sg_monitoring_id]
  volume_size          = 50
  create_eip           = false
  iam_instance_profile = module.iam.instance_profile_name

  user_data = templatefile("${path.module}/templates/monitoring/userdata.sh.tpl", {
    compose_content     = templatefile("${path.module}/templates/monitoring/docker-compose.yml.tpl", {
      db_username = var.db_username
      db_password = var.db_password
      db_name     = var.db_name
      rds_address = module.rds.address
    })
    prometheus_config   = file("${path.module}/templates/monitoring/prometheus.yml")
    loki_config         = templatefile("${path.module}/templates/monitoring/loki-config.yml.tpl", {
      aws_region          = var.region
      s3_logs_bucket_name = var.s3_logs_bucket_name
    })
    tempo_config        = file("${path.module}/templates/monitoring/tempo-config.yml")
    grafana_datasources = file("${path.module}/templates/monitoring/grafana-datasources.yml")
  })

  tags = {
    Name        = "${var.prefix}-monitoring-server"
    Environment = var.environment
    Role        = "monitoring"
  }
}

module "main_server" {
  source = "./modules/compute"

  ami_id               = data.aws_ami.ubuntu.id
  instance_type        = var.main_instance_type
  key_name             = aws_key_pair.main.key_name
  subnet_id            = module.network.public_subnet_a_id
  sg_ids               = [module.network.sg_main_id]
  volume_size          = 30
  iam_instance_profile = module.iam.instance_profile_name
  create_eip           = true

  user_data = templatefile("${path.module}/templates/main/userdata.sh.tpl", {
    compose_content = file("${path.module}/templates/main/docker-compose.yml")
    alloy_config    = templatefile("${path.module}/templates/main/alloy-config.alloy.tpl", {
      monitoring_private_ip = module.monitoring.private_ip
    })
  })

  tags = {
    Name        = "${var.prefix}-main-server"
    Environment = var.environment
    Role        = "application"
  }
}

module "loadtest" {
  source = "./modules/compute"
  count  = var.enable_loadtest ? 1 : 0

  ami_id        = data.aws_ami.ubuntu.id
  instance_type = var.loadtest_instance_type
  key_name      = aws_key_pair.main.key_name
  subnet_id     = module.network.public_subnet_a_id
  sg_ids        = [module.network.sg_loadtest_id]
  volume_size   = 20
  create_eip    = false

  user_data = file("${path.module}/templates/loadtest/userdata.sh")

  tags = {
    Name        = "${var.prefix}-loadtest-server"
    Environment = var.environment
    Role        = "loadtest"
  }
}

module "rds" {
  source = "./modules/rds"

  prefix         = var.prefix
  environment    = var.environment
  subnet_ids     = module.network.private_subnet_ids
  sg_ids         = [module.network.sg_rds_id]
  db_name        = var.db_name
  db_username    = var.db_username
  db_password    = var.db_password
  instance_class = var.db_instance_class
}

module "route53" {
  source = "./modules/route53"

  domain_name = var.domain_name
  record_ip   = module.main_server.eip_public_ip
  environment = var.environment
}
