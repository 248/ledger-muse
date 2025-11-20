output "service_url" {
  description = "URL of the Cloud Run service"
  value       = google_cloud_run_service.api.status[0].url
}

output "service_name" {
  description = "Cloud Run service name"
  value       = google_cloud_run_service.api.name
}

output "service_id" {
  description = "Cloud Run service ID"
  value       = google_cloud_run_service.api.id
}
