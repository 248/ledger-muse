variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "service_account_id" {
  description = "Service account ID (without domain)"
  type        = string
}

variable "service_account_display_name" {
  description = "Display name for the service account"
  type        = string
}

variable "service_account_roles" {
  description = "List of IAM roles to attach to the service account"
  type        = list(string)
  default     = []
}
