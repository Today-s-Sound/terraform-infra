terraform {
  cloud {
    organization = "test0217"
    hostname     = "app.terraform.io" # default

    workspaces {
      name = "terraform-gcp-tfc-workflow"
    }
  }
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# SSH Key for all servers
resource "tls_private_key" "main" {
  algorithm = "RSA"
}

locals {
  private_key_filename = "${var.prefix}-ssh-key.pem"
}
