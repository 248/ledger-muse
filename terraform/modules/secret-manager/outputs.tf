output "secret_name" {
  description = "Full resource name of the secret"
  value       = google_secret_manager_secret.secret.name
}

output "secret_id" {
  description = "Secret ID"
  value       = google_secret_manager_secret.secret.secret_id
}

output "secret_version" {
  description = "Latest version of the secret"
  value       = google_secret_manager_secret_version.version.name
}
