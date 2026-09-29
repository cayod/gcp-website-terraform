mock_provider "google" {}

variables {
  name        = "site-test"
  bucket_name = "demo-project-site"
  location    = "us-central1"
  html        = "<!doctype html><title>test</title>"
}

run "uploads_the_html_as_the_index_page" {
  command = plan

  assert {
    condition     = google_storage_bucket_object.index.name == "index.html" && google_storage_bucket_object.index.content == var.html
    error_message = "The HTML must be uploaded as index.html."
  }

  assert {
    condition     = google_storage_bucket.site.website[0].main_page_suffix == "index.html"
    error_message = "Requests for / must be served index.html."
  }
}

run "never_serves_a_stale_page_after_a_deploy" {
  command = plan

  assert {
    condition     = google_storage_bucket_object.index.cache_control == "no-cache"
    error_message = "index.html must be revalidated on every request so a redeploy is visible immediately."
  }

  assert {
    condition     = startswith(google_storage_bucket_object.index.content_type, "text/html")
    error_message = "index.html must be served as text/html."
  }
}

run "grants_only_public_read_on_objects" {
  command = plan

  assert {
    condition     = google_storage_bucket_iam_member.public_read.member == "allUsers" && google_storage_bucket_iam_member.public_read.role == "roles/storage.objectViewer"
    error_message = "The public may only read objects."
  }

  assert {
    condition     = google_storage_bucket.site.uniform_bucket_level_access == true
    error_message = "Access must be controlled by bucket IAM only, without object ACLs."
  }
}

run "serves_through_cloud_cdn" {
  command = plan

  assert {
    condition     = google_compute_backend_bucket.site.enable_cdn == true && google_compute_backend_bucket.site.bucket_name == var.bucket_name
    error_message = "The backend bucket must front the site bucket with Cloud CDN."
  }
}

run "rejects_empty_html" {
  command = plan

  variables {
    html = ""
  }

  expect_failures = [var.html]
}
