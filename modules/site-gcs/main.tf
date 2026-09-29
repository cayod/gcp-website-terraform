# The bucket only holds public site content, generated from the repository:
# Google-managed encryption is enough, and git is the version history, so a rollback
# is a revert deployed by the pipeline rather than a restore of an object version.
#trivy:ignore:AVD-GCP-0066
#trivy:ignore:AVD-GCP-0078
resource "google_storage_bucket" "site" {
  name                        = var.bucket_name
  location                    = var.location
  uniform_bucket_level_access = true
  force_destroy               = true

  website {
    main_page_suffix = "index.html"
  }
}

# Backend buckets read objects anonymously, so the public must be able to read them.
#trivy:ignore:AVD-GCP-0001
resource "google_storage_bucket_iam_member" "public_read" {
  bucket = google_storage_bucket.site.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

# no-cache makes the edge revalidate the page on every request, so a redeploy is visible at once.
resource "google_storage_bucket_object" "index" {
  bucket        = google_storage_bucket.site.name
  name          = "index.html"
  content       = var.html
  content_type  = "text/html; charset=utf-8"
  cache_control = "no-cache"
}

resource "google_compute_backend_bucket" "site" {
  name        = var.name
  bucket_name = google_storage_bucket.site.name
  enable_cdn  = true

  cdn_policy {
    cache_mode        = "CACHE_ALL_STATIC"
    default_ttl       = var.cdn_default_ttl_seconds
    serve_while_stale = var.cdn_default_ttl_seconds
  }
}
