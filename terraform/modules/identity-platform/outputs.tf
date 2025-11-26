output "authorized_domains" {
  description = "Authorized domains configured for Identity Platform"
  value       = google_identity_platform_config.this.authorized_domains
}
