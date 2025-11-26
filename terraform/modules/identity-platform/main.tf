resource "google_project_service" "identity_platform" {
  project = var.project_id
  service = "identitytoolkit.googleapis.com"

  disable_on_destroy = false
}

resource "google_identity_platform_config" "this" {
  project = var.project_id

  sign_in {
    email {
      enabled = true
    }
  }

  authorized_domains = var.authorized_domains

  depends_on = [google_project_service.identity_platform]
}
