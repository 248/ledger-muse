variable "project_id" {
  description = "GCP project ID where the secret will be created"
  type        = string
}

variable "secret_id" {
  description = "Unique identifier for the secret"
  type        = string
}

variable "secret_data" {
  description = "The actual secret data to store"
  type        = string
  sensitive   = true
}

variable "accessor_members" {
  description = "List of members (service accounts) that can access this secret"
  type        = list(string)
  default     = []
}

variable "labels" {
  description = "Labels to attach to the secret"
  type        = map(string)
  default     = {}
}
