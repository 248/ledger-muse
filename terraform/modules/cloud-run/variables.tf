variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "service_name" {
  description = "Name of the Cloud Run service"
  type        = string
}

variable "region" {
  description = "Region for the Cloud Run service"
  type        = string
}

variable "container_image" {
  description = "Container image to deploy"
  type        = string
}

variable "environment" {
  description = "Environment identifier (e.g. staging, prod)"
  type        = string
}

variable "service_account_email" {
  description = "Service account email used by the service"
  type        = string
}

variable "min_instances" {
  description = "Minimum number of Cloud Run instances"
  type        = number
  default     = 0
}

variable "max_instances" {
  description = "Maximum number of Cloud Run instances"
  type        = number
  default     = 10
}

variable "memory" {
  description = "Memory allocation for the container"
  type        = string
  default     = "512Mi"
}

variable "cpu" {
  description = "CPU allocation for the container"
  type        = string
  default     = "1"
}

variable "env_vars" {
  description = "Environment variables for the container"
  type        = map(string)
  default     = {}
}
