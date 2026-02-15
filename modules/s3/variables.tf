variable "bucket_name" {
  description = "S3 bucket name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "enable_versioning" {
  description = "Enable bucket versioning"
  type        = bool
  default     = true
}

variable "enable_cors" {
  description = "Enable CORS for browser uploads"
  type        = bool
  default     = false
}

variable "enable_lifecycle" {
  description = "Enable lifecycle rule for auto-deletion"
  type        = bool
  default     = false
}

variable "lifecycle_expiration_days" {
  description = "Number of days before objects are deleted"
  type        = number
  default     = 90
}
