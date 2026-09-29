locals {
  web_vm_project_roles = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
  ])

  # Read-only: plans run with -lock=false, so no write access to the state bucket is needed.
  terraform_plan_project_roles = toset([
    "roles/iam.securityReviewer",
    "roles/storage.objectViewer",
    "roles/viewer",
  ])

  # Manages application resources only: no identities, no project IAM, no network changes.
  terraform_apply_project_roles = toset([
    "roles/compute.instanceAdmin.v1",
    "roles/compute.loadBalancerAdmin",
    "roles/compute.networkUser",
    "roles/storage.admin",
  ])
}

resource "google_service_account" "web_vm" {
  account_id   = "web-vm"
  display_name = "Web VM runtime"
  description  = "Runs the web VMs of the MIG stack."

  depends_on = [google_project_service.required]
}

resource "google_service_account" "terraform_plan" {
  account_id   = "terraform-plan"
  display_name = "Terraform plan (CI)"
  description  = "Read-only identity used by pull request plans."

  depends_on = [google_project_service.required]
}

resource "google_service_account" "terraform_apply" {
  account_id   = "terraform-apply"
  display_name = "Terraform apply (CI)"
  description  = "Deploys the stacks from the ${var.environment} GitHub Environment."

  depends_on = [google_project_service.required]
}

resource "google_project_iam_member" "web_vm" {
  for_each = local.web_vm_project_roles

  project = var.project_id
  role    = each.value
  member  = google_service_account.web_vm.member
}

resource "google_project_iam_member" "terraform_plan" {
  for_each = local.terraform_plan_project_roles

  project = var.project_id
  role    = each.value
  member  = google_service_account.terraform_plan.member
}

resource "google_project_iam_member" "terraform_apply" {
  for_each = local.terraform_apply_project_roles

  project = var.project_id
  role    = each.value
  member  = google_service_account.terraform_apply.member
}

resource "google_artifact_registry_repository_iam_member" "web_vm_reader" {
  location   = google_artifact_registry_repository.dockerhub.location
  repository = google_artifact_registry_repository.dockerhub.name
  role       = "roles/artifactregistry.reader"
  member     = google_service_account.web_vm.member
}

# The apply identity may attach the VM identity to instances, and nothing else.
resource "google_service_account_iam_member" "terraform_apply_uses_web_vm" {
  service_account_id = google_service_account.web_vm.name
  role               = "roles/iam.serviceAccountUser"
  member             = google_service_account.terraform_apply.member
}
