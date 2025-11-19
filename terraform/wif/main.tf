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

data "google_project" "this" {}

resource "google_service_account" "deployer" {
  account_id   = var.service_account_id
  display_name = var.service_account_display_name
}

resource "google_iam_workload_identity_pool" "pool" {
  workload_identity_pool_id = var.wif_pool_id
  display_name              = var.wif_pool_display_name
  description               = "GitHub OIDC pool for CI/CD"
}

resource "google_iam_workload_identity_pool_provider" "github" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.pool.workload_identity_pool_id
  workload_identity_pool_provider_id = var.wif_provider_id
  display_name                       = var.wif_provider_display_name
  description                        = "GitHub Actions OIDC provider"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }

  attribute_mapping = {
    "google.subject"          = "assertion.sub"
    "attribute.actor"         = "assertion.actor"
    "attribute.repository"    = "assertion.repository"
    "attribute.repository_id" = "assertion.repository_id"
    "attribute.ref"           = "assertion.ref"
  }

  # Restrict to the target repository. Must reference mapped attributes per API requirements.
  attribute_condition = "attribute.repository==\"${var.github_repository}\""
}

# Allow GitHub repo to impersonate the service account via WIF
resource "google_service_account_iam_member" "wif_binding" {
  service_account_id = google_service_account.deployer.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.pool.name}/attribute.repository/${var.github_repository}"
}

# Attach deploy roles to the service account
resource "google_project_iam_member" "deploy_roles" {
  for_each = toset(var.service_account_roles)

  project = data.google_project.this.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.deployer.email}"
}
