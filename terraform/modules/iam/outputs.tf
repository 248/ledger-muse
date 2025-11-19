output "service_account_email" {
  description = "Email of the created service account"
  value       = google_service_account.backend.email
}

output "service_account_name" {
  description = "Resource name of the service account"
  value       = google_service_account.backend.name
}

output "service_account_id" {
  description = "Account ID of the service account"
  value       = google_service_account.backend.account_id
}
