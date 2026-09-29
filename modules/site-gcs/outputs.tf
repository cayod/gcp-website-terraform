output "backend_id" {
  description = "ID of the backend bucket, to route load balancer traffic to."
  value       = google_compute_backend_bucket.site.id
}

output "bucket_name" {
  description = "Bucket that stores the site."
  value       = google_storage_bucket.site.name
}

output "content_md5" {
  description = "MD5 hash of the deployed index.html, which changes on every redeployment."
  value       = google_storage_bucket_object.index.md5hash
}
