module "artifact_registry" {
  source = "../../modules/artifact-registry"

  project_id   = var.project_id
  region       = var.region
  repository_id = var.artifact_registry_repository_id
  description   = var.artifact_registry_description
}
