output "bucket_name" {
  description = "Name of the Cloud Storage bucket"
  value       = google_storage_bucket.this.name
}

output "bucket_url" {
  description = "URL of the Cloud Storage bucket"
  value       = google_storage_bucket.this.url
}

output "bucket_id" {
  description = "ID of the Cloud Storage bucket"
  value       = google_storage_bucket.this.id
}
