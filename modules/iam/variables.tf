variable "prefix" {
  description = "Resource name prefix"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "s3_bucket_arns" {
  description = "List of S3 bucket ARNs for policy"
  type        = list(string)
}
