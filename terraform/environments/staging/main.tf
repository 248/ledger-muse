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
}
