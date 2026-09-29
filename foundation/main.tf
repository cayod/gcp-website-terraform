locals {
  labels = {
    environment = var.environment
    managed-by  = "terraform"
  }

  # One static IP per hosting approach, so each stack keeps its endpoint across redeployments.
  sites = toset(["gcs", "mig"])

  # Enabling any other API goes through these two, so they are enabled first.
  # Enabling everything in parallel races on a new project and fails with a 403.
  base_services = toset([
    "cloudresourcemanager.googleapis.com",
    "serviceusage.googleapis.com",
  ])

  required_services = toset([
    "artifactregistry.googleapis.com",
    "billingbudgets.googleapis.com",
    "compute.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "storage.googleapis.com",
    "sts.googleapis.com",
  ])
}

resource "google_project_service" "base" {
  for_each = local.base_services

  service            = each.value
  disable_on_destroy = false
}

resource "google_project_service" "required" {
  for_each = local.required_services

  service            = each.value
  disable_on_destroy = false

  depends_on = [google_project_service.base]
}

moved {
  from = google_project_service.required["cloudresourcemanager.googleapis.com"]
  to   = google_project_service.base["cloudresourcemanager.googleapis.com"]
}

moved {
  from = google_project_service.required["serviceusage.googleapis.com"]
  to   = google_project_service.base["serviceusage.googleapis.com"]
}

# Read after the APIs are enabled; the project number is needed by the budget filter.
data "google_project" "this" {
  project_id = var.project_id

  depends_on = [google_project_service.required]
}
