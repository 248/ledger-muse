variable "project_id" {
  description = "GCP project ID (suffixes the remote state bucket name)"
  type        = string
}

variable "location" {
  description = "Default region/location for the state bucket"
  type        = string
  default     = null
}

variable "region" {
  description = "Alternative input for location (accepted to avoid var warnings when using common.auto.tfvars)"
  type        = string
  default     = null
}

variable "state_admin_members" {
  description = "Principals to grant roles/storage.objectAdmin on the state bucket (e.g., user:you@example.com, serviceAccount:ci@project.iam.gserviceaccount.com)"
  type        = list(string)
  default     = []
}
