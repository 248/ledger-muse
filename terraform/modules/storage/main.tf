resource "google_storage_bucket" "this" {
  project  = var.project_id
  name     = var.bucket_name
  location = var.region

  force_destroy = var.force_destroy

  uniform_bucket_level_access = true

  lifecycle_rule {
    condition {
      age = var.lifecycle_age_days
    }
    action {
      type = "Delete"
    }
  }

  dynamic "encryption" {
    for_each = var.kms_key_name == null ? [] : [var.kms_key_name]
    content {
      default_kms_key_name = encryption.value
    }
  }
}
