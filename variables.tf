variable "prefix" {
  description = "This prefix will be included in the name of most resources."
}

variable "project_id" {
  description = "The GCP project ID where the resources will be created."
  default     = "Today-Sound"
}

variable "region" {
  description = "The region where the resources are created."
  default     = "asia-northeast3"
}

variable "zone" {
  description = "The zone where the compute instance will be created."
  default     = "asia-northeast3-a"
}

variable "subnet_prefix" {
  description = "The address prefix to use for the subnet."
  default     = "10.0.10.0/24"
}

variable "machine_type" {
  description = "Specifies the GCP machine type for monitoring server."
  default     = "e2-small"
}

variable "main_server_machine_type" {
  description = "Specifies the GCP machine type for main application server."
  default     = "e2-medium"
}

variable "height" {
  default     = "400"
  description = "Image height in pixels."
}

variable "width" {
  default     = "600"
  description = "Image width in pixels."
}

variable "placeholder" {
  default     = "placekitten.com"
  description = "Image-as-a-service URL. Some other fun ones to try are fillmurray.com, placecage.com, placebeard.it, loremflickr.com, baconmockup.com, placeimg.com, placebear.com, placeskull.com, stevensegallery.com, placedog.net"
}

variable "environment" {
  type        = string
  description = "Define infrastructure’s environment"
  default     = "dev"
  validation {
    condition     = contains(["dev", "qa", "prod"], var.environment)
    error_message = "The environment value must be dev, qa, or prod."
  }
}