output "service_account_email" {
  value       = google_service_account.deployer.email
  description = "Deployer service account email"
}

output "wif_pool_name" {
  value       = google_iam_workload_identity_pool.pool.name
  description = "Full resource name of the Workload Identity Pool"
}

output "wif_provider_name" {
  value       = google_iam_workload_identity_pool_provider.github.name
  description = "Full resource name of the Workload Identity Provider"
}
