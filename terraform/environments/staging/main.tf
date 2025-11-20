module "artifact_registry" {
  source = "../../modules/artifact-registry"

  project_id   = var.project_id
  region       = var.region
  repository_id = var.artifact_registry_repository_id
  description   = var.artifact_registry_description
}

module "backend_api_service_account" {
  source = "../../modules/iam"

  project_id                   = var.project_id
  service_account_id           = var.backend_api_service_account_id
  service_account_display_name = var.backend_api_service_account_display_name
  service_account_roles        = var.backend_api_service_account_roles
}
