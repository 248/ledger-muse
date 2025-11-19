terraform {
  required_version = ">= 1.6.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_service_account" "terraform_runner" {
  account_id   = var.service_account_id
  display_name = var.service_account_display_name
  description  = "Service account for Terraform operations"
}

resource "google_project_iam_member" "roles" {
  for_each = toset(var.project_roles)

  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.terraform_runner.email}"
}
