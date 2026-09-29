# The foundation is applied by a human with user credentials.
# Some APIs, such as Billing Budgets, reject user credentials without a quota project,
# so every request is billed to the target project.
provider "google" {
  project               = var.project_id
  region                = var.region
  billing_project       = var.project_id
  user_project_override = true
  default_labels        = local.labels
}

provider "google-beta" {
  project               = var.project_id
  region                = var.region
  billing_project       = var.project_id
  user_project_override = true
  default_labels        = local.labels
}
