# API有効化
resource "google_project_service" "artifactregistry" {
  project = var.project_id
  service = "artifactregistry.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "cloudrun" {
  project = var.project_id
  service = "run.googleapis.com"

  disable_on_destroy = false
}

# 将来のPhaseで使用予定のAPI（Phase 3: Datastore、Phase 4: Pub/Sub）
resource "google_project_service" "datastore" {
  project = var.project_id
  service = "datastore.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "pubsub" {
  project = var.project_id
  service = "pubsub.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "secretmanager" {
  project = var.project_id
  service = "secretmanager.googleapis.com"

  disable_on_destroy = false
}

module "identity_platform" {
  source = "../../modules/identity-platform"

  project_id         = var.project_id
  authorized_domains = var.identity_platform_authorized_domains
}

# Artifact Registry
module "artifact_registry" {
  source = "../../modules/artifact-registry"

  project_id   = var.project_id
  region       = var.region
  repository_id = var.artifact_registry_repository_id
  description   = var.artifact_registry_description

  depends_on = [google_project_service.artifactregistry]
}

module "backend_api_service_account" {
  source = "../../modules/iam"

  project_id                   = var.project_id
  service_account_id           = var.backend_api_service_account_id
  service_account_display_name = var.backend_api_service_account_display_name
  service_account_roles        = var.backend_api_service_account_roles
}

module "backend_api_cloud_run" {
  source = "../../modules/cloud-run"

  project_id           = var.project_id
  region               = var.region
  service_name         = var.backend_api_cloud_run_service_name
  container_image      = var.backend_api_cloud_run_container_image
  environment          = var.backend_api_cloud_run_environment
  service_account_email = module.backend_api_service_account.service_account_email
  min_instances        = var.backend_api_cloud_run_min_instances
  max_instances        = var.backend_api_cloud_run_max_instances
  memory               = var.backend_api_cloud_run_memory
  cpu                  = var.backend_api_cloud_run_cpu

  env_vars = {
    FIREBASE_PROJECT_ID = var.project_id
    PORT                = "8080"
  }

  depends_on = [google_project_service.cloudrun]
}

# Secret Manager - Backend API URL for App Hosting
module "backend_api_url_secret" {
  source = "../../modules/secret-manager"

  project_id       = var.project_id
  secret_id        = var.backend_api_url_secret_id
  secret_data      = var.backend_api_url
  accessor_members = var.backend_api_url_secret_accessors

  labels = {
    environment = "staging"
    purpose     = "app-hosting-config"
  }

  depends_on = [google_project_service.secretmanager]
}
