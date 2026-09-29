locals {
  state_soft_delete_seconds      = 7 * 24 * 60 * 60
  state_noncurrent_versions_kept = 10
}

# Google-managed encryption is accepted: a customer-managed KMS key adds cost and a way
# to lose the state (key destruction) without a compliance requirement that justifies it.
#trivy:ignore:AVD-GCP-0066
resource "google_storage_bucket" "tfstate" {
  name                        = "${var.project_id}-tfstate"
  location                    = var.region
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  force_destroy               = var.state_bucket_force_destroy

  versioning {
    enabled = true
  }

  soft_delete_policy {
    retention_duration_seconds = local.state_soft_delete_seconds
  }

  lifecycle_rule {
    condition {
      num_newer_versions = local.state_noncurrent_versions_kept
      with_state         = "ARCHIVED"
    }
    action {
      type = "Delete"
    }
  }

  depends_on = [google_project_service.required]
}
