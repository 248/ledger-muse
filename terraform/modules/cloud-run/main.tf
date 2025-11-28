locals {
  autoscaling_annotations = {
    "autoscaling.knative.dev/minScale" = tostring(var.min_instances)
    "autoscaling.knative.dev/maxScale" = tostring(var.max_instances)
  }
}

resource "google_cloud_run_service" "api" {
  project  = var.project_id
  name     = var.service_name
  location = var.region

  autogenerate_revision_name = true

  template {
    metadata {
      annotations = local.autoscaling_annotations
    }

    spec {
      service_account_name = var.service_account_email

      containers {
        image = var.container_image

        dynamic "env" {
          for_each = merge(
            { ENV = var.environment },
            var.env_vars
          )
          content {
            name  = env.key
            value = env.value
          }
        }

        resources {
          limits = {
            memory = var.memory
            cpu    = var.cpu
          }
        }
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}
