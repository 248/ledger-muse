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

variable "backend_api_cloud_run_service_name" {
  description = "Cloud Run service name for the staging backend API"
  type        = string
  default     = "ledger-muse-api-staging"
}

variable "backend_api_cloud_run_container_image" {
  description = "Container image used for the staging backend API deployment"
  type        = string
  default     = "gcr.io/cloudrun/hello"
}

variable "backend_api_cloud_run_environment" {
  description = "Environment label injected into the Cloud Run service"
  type        = string
  default     = "staging"
}

variable "backend_api_cloud_run_min_instances" {
  description = "Minimum instances for the backend API Cloud Run service"
  type        = number
  default     = 0
}

variable "backend_api_cloud_run_max_instances" {
  description = "Maximum instances for the backend API Cloud Run service"
  type        = number
  default     = 2
}

variable "backend_api_cloud_run_memory" {
  description = "Memory allocation for the backend API Cloud Run service"
  type        = string
  default     = "512Mi"
}

variable "backend_api_cloud_run_cpu" {
  description = "CPU allocation for the backend API Cloud Run service"
  type        = string
  default     = "1"
}

variable "identity_platform_authorized_domains" {
  description = "Authorized domains for Identity Platform sign-in"
  type        = list(string)
  default     = []
}

variable "backend_api_url" {
  description = "Backend API URL for App Hosting environment variables"
  type        = string
  # This value must be provided via a .tfvars file (e.g., secret-manager.auto.tfvars)
  # to avoid accidental exposure of environment-specific URLs in version control.
}

variable "backend_api_url_secret_id" {
  description = "Secret ID for storing backend API URL"
  type        = string
  default     = "BACKEND_API_BASE_STAGING"
}

variable "backend_api_url_secret_accessors" {
  description = "Service accounts that can access the backend API URL secret"
  type        = list(string)
  default     = []
}
