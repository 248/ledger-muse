variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "Default region"
  type        = string
  default     = "asia-northeast1"
}

variable "service_account_id" {
  description = "Service account ID (without domain), e.g. firebase-apphosting-deployer"
  type        = string
  default     = "firebase-apphosting-deployer"
}

variable "service_account_display_name" {
  description = "Service account display name"
  type        = string
  default     = "Firebase App Hosting Deployer"
}

variable "service_account_roles" {
  description = "Project roles to attach to the App Hosting deployer service account"
  type        = list(string)
  default = [
    "roles/firebasehosting.admin",
    "roles/iam.serviceAccountUser"
  ]
}
