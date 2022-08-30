resource "google_cloud_run_service" "dashboard" {
  name     = "fourkeys-grafana-dashboard"
  location = var.google_region

  template {
    spec {
      containers {
        ports {
          container_port = 3000
        }
        image = "gcr.io/${var.google_project_id}/fourkeys-grafana-dashboard"
        env {
          name  = "PROJECT_NAME"
          value = var.google_project_id
        }
        env {
          name  = "BQ_REGION"
          value = var.bigquery_region
        }

        env {
          name = "GF_AUTH_GOOGLE_CLIENT_ID"
          value_from {
            secret_key_ref {
              name = "OAUTH_USER"
              key  = "latest"
            }
          }
        }
        env {
          name = "GF_AUTH_GOOGLE_CLIENT_SECRET"
          value_from {
            secret_key_ref {
              name = "OAUTH_SECRET"
              key  = "latest"
            }
          }
        }

      }
      service_account_name = var.fourkeys_service_account_email
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
  metadata {
    labels = { "created_by" : "fourkeys" }
  }
  autogenerate_revision_name = true
}

resource "google_cloud_run_service_iam_binding" "noauth" {
  location = var.google_region
  project  = var.google_project_id
  service  = "fourkeys-grafana-dashboard"

  role       = "roles/run.invoker"
  members    = ["allUsers"]
  depends_on = [google_cloud_run_service.dashboard]
}
