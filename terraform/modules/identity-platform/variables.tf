variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "authorized_domains" {
  description = "List of authorized domains for Identity Platform sign-in"
  type        = list(string)
  default     = []
}
