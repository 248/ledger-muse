variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "Default region (for compatibility with other modules)"
  type        = string
  default     = "asia-northeast1"
}

variable "service_account_id" {
  description = "Service account ID (without domain), e.g. github-deployer"
  type        = string
}

variable "service_account_display_name" {
  description = "Service account display name"
  type        = string
  default     = "GitHub Deployer"
}

variable "service_account_roles" {
  description = "Project roles to attach to the deployer service account"
  type        = list(string)
  default = [
    "roles/run.admin",
    "roles/artifactregistry.writer",
    "roles/iam.serviceAccountUser"
  ]
}

variable "wif_pool_id" {
  description = "Workload Identity Pool ID (short name)"
  type        = string
  default     = "github-pool"
}

variable "wif_pool_display_name" {
  description = "Workload Identity Pool display name"
  type        = string
  default     = "GitHub Pool"
}

variable "wif_provider_id" {
  description = "Workload Identity Provider ID (short name)"
  type        = string
  default     = "github"
}

variable "wif_provider_display_name" {
  description = "Workload Identity Provider display name"
  type        = string
  default     = "GitHub OIDC"
}

variable "github_repository" {
  description = "GitHub repo allowed to impersonate (owner/repo)"
  type        = string
}
