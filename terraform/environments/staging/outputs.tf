output "artifact_registry_repository_id" {
  description = "Artifact Registry repository id for staging"
  value       = module.artifact_registry.repository_id
}

output "artifact_registry_url" {
  description = "Artifact Registry repository URL"
  value       = module.artifact_registry.repository_url
}

output "backend_api_service_account_email" {
  description = "Email of the backend API service account for staging"
  value       = module.backend_api_service_account.service_account_email
}

output "backend_api_cloud_run_service_url" {
  description = "URL of the staging backend API Cloud Run service"
  value       = module.backend_api_cloud_run.service_url
}

output "identity_platform_authorized_domains" {
  description = "Authorized domains configured for Identity Platform (staging)"
  value       = module.identity_platform.authorized_domains
}

output "backend_api_url_secret_name" {
  description = "Full resource name of the backend API URL secret"
  value       = module.backend_api_url_secret.secret_name
}

output "backend_api_url_secret_id" {
  description = "Secret ID for backend API URL"
  value       = module.backend_api_url_secret.secret_id
}
