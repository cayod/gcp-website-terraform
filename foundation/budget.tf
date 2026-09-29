locals {
  budget_alert_thresholds = [0.5, 0.9, 1.0]
}

# The amount uses the currency of the billing account, so no currency is hardcoded.
resource "google_billing_budget" "project" {
  count = var.billing_account == null ? 0 : 1

  billing_account = var.billing_account
  display_name    = "${var.project_id} monthly budget"

  budget_filter {
    projects = ["projects/${data.google_project.this.number}"]
  }

  amount {
    specified_amount {
      units = tostring(var.budget_amount)
    }
  }

  dynamic "threshold_rules" {
    for_each = local.budget_alert_thresholds

    content {
      threshold_percent = threshold_rules.value
    }
  }
}
