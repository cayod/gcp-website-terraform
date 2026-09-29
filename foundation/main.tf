locals {
  labels = {
    environment = var.environment
    managed-by  = "terraform"
  }

  # One static IP per hosting approach, so each stack keeps its endpoint across redeployments.
  sites = toset(["gcs", "mig"])

  required_services = toset([
    "artifactregistry.googleapis.com",
    "billingbudgets.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "serviceusage.googleapis.com",
    "storage.googleapis.com",
    "sts.googleapis.com",
  ])
}

resource "google_project_service" "required" {
  for_each = local.required_services

  service            = each.value
  disable_on_destroy = false
}

# Read after the APIs are enabled; the project number is needed by the budget filter.
data "google_project" "this" {
  project_id = var.project_id

  depends_on = [google_project_service.required]
}
