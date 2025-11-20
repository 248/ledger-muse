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
