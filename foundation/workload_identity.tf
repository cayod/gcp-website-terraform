locals {
  github_oidc_issuer = "https://token.actions.githubusercontent.com"
  github_subject     = "principal://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/subject/repo:${var.github_repository}"
}

resource "google_iam_workload_identity_pool" "github" {
  workload_identity_pool_id = "github"
  display_name              = "GitHub Actions"

  depends_on = [google_project_service.required]
}

# Only tokens issued for this exact repository are accepted, matched by its immutable numeric ID.
resource "google_iam_workload_identity_pool_provider" "github" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-actions"
  display_name                       = "GitHub Actions OIDC"
  attribute_condition                = "assertion.repository_id == '${var.github_repository_id}'"

  attribute_mapping = {
    "google.subject"          = "assertion.sub"
    "attribute.repository"    = "assertion.repository"
    "attribute.repository_id" = "assertion.repository_id"
  }

  oidc {
    issuer_uri = local.github_oidc_issuer
  }
}

resource "google_service_account_iam_member" "github_pull_requests_plan" {
  service_account_id = google_service_account.terraform_plan.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "${local.github_subject}:pull_request"
}

# Only jobs running in the matching GitHub Environment can deploy, so prod approvals are enforced.
resource "google_service_account_iam_member" "github_environment_apply" {
  service_account_id = google_service_account.terraform_apply.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "${local.github_subject}:environment:${var.environment}"
}
