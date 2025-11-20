variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "bucket_name" {
  description = "Cloud Storage bucket name"
  type        = string
}

variable "region" {
  description = "Bucket location"
  type        = string
}

variable "force_destroy" {
  description = "Allow bucket deletion even when objects exist"
  type        = bool
  default     = false
}

variable "lifecycle_age_days" {
  description = "Delete objects older than this number of days"
  type        = number
  default     = 90
}

variable "kms_key_name" {
  description = "Optional KMS key for default encryption"
  type        = string
  default     = null
}
