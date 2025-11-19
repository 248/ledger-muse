terraform {
  required_version = "~> 1.9.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

variable "project_id" {
  description = "GCP project ID shared across environments"
  type        = string
}

variable "region" {
  description = "Default region for shared providers"
  type        = string
  default     = "asia-northeast1"
}

provider "google" {
  project = var.project_id
  region  = var.region
}
