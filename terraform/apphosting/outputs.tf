output "service_account_email" {
  value       = google_service_account.apphosting.email
  description = "App Hosting deployer service account email"
}
