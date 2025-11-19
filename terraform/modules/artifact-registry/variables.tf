variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "repository_id" {
  description = "Artifact Registry repository ID"
  type        = string
}

variable "region" {
  description = "Region for Artifact Registry"
  type        = string
}

variable "description" {
  description = "Description for the repository"
  type        = string
  default     = "Docker repository for Ledger Muse"
}
