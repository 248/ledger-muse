output "artifact_registry_repository_id" {
  description = "Artifact Registry repository id for staging"
  value       = module.artifact_registry.repository_id
}

output "artifact_registry_url" {
  description = "Artifact Registry repository URL"
  value       = module.artifact_registry.repository_url
}
