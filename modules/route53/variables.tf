variable "domain_name" {
  description = "Domain name for Route53 hosted zone"
  type        = string
  default     = ""
}

variable "record_ip" {
  description = "IP address for the A record"
  type        = string
  default     = ""
}

variable "environment" {
  description = "Environment name"
  type        = string
}
