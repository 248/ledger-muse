variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "Primary region for staging"
  type        = string
  default     = "asia-northeast1"
}

variable "artifact_registry_repository_id" {
  description = "Artifact Registry repository id for staging"
  type        = string
  default     = "ledger-muse"
}

variable "artifact_registry_description" {
  description = "Description for the staging Artifact Registry"
  type        = string
  default     = "Ledger Muse staging Docker repository"
}

variable "backend_api_service_account_id" {
  description = "Service account ID for the staging backend API runtime"
  type        = string
  default     = "backend-api-staging-sa"
}

variable "backend_api_service_account_display_name" {
  description = "Display name for the backend API staging service account"
  type        = string
  default     = "Ledger Muse Backend API (staging)"
}

variable "backend_api_service_account_roles" {
  description = "IAM roles attached to the backend API staging service account"
  type        = list(string)
  default = [
    "roles/datastore.user",
    "roles/storage.objectAdmin",
    "roles/pubsub.publisher",
    "roles/serviceusage.serviceUsageConsumer",
  ]
}
