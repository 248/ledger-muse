variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "Default region (kept for provider compatibility)"
  type        = string
  default     = "asia-northeast1"
}

variable "service_account_id" {
  description = "Service account ID (without domain), e.g. terraform-runner"
  type        = string
  default     = "terraform-runner"
}

variable "service_account_display_name" {
  description = "Service account display name"
  type        = string
  default     = "Terraform Runner"
}

variable "project_roles" {
  description = "Project roles to attach to the Terraform runner SA"
  type        = list(string)
  default     = []
}
