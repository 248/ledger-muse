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
  region  = local.effective_location
}

locals {
  effective_location = coalesce(var.location, var.region, "asia-northeast1")
}

resource "google_storage_bucket" "state" {
  name                        = "${var.project_id}-terraform-state"
  location                    = local.effective_location
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_storage_bucket_iam_member" "state_admin" {
  for_each = toset(var.state_admin_members)

  bucket = google_storage_bucket.state.name
  role   = "roles/storage.objectAdmin"
  member = each.value
}
