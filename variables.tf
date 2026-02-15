variable "prefix" {
  description = "This prefix will be included in the name of most resources."
  default     = "todaysound"
}

variable "region" {
  description = "The AWS region where resources are created."
  default     = "ap-northeast-2"
}

variable "environment" {
  type        = string
  description = "Define infrastructure's environment"
  default     = "dev"
  validation {
    condition     = contains(["dev", "qa", "prod"], var.environment)
    error_message = "The environment value must be dev, qa, or prod."
  }
}

# EC2 Instance Types
variable "main_instance_type" {
  description = "EC2 instance type for main application server."
  default     = "t3.medium"
}

variable "monitoring_instance_type" {
  description = "EC2 instance type for monitoring server."
  default     = "t3.medium"
}

variable "loadtest_instance_type" {
  description = "EC2 instance type for load test server."
  default     = "t3.medium"
}

variable "enable_loadtest" {
  description = "Enable or disable load test server."
  type        = bool
  default     = false
}

# RDS
variable "db_instance_class" {
  description = "RDS instance class."
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Name of the PostgreSQL database."
  default     = "todaysound"
}

variable "db_username" {
  description = "Master username for RDS."
  sensitive   = true
}

variable "db_password" {
  description = "Master password for RDS."
  sensitive   = true
}

# S3
variable "s3_bucket_name" {
  description = "S3 bucket name for presigned URL uploads."
}

# Route53
variable "domain_name" {
  description = "Domain name for Route53 hosted zone. Leave empty to skip."
  default     = ""
}

# Security
variable "allowed_ssh_cidrs" {
  description = "CIDR blocks allowed to SSH into servers."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
