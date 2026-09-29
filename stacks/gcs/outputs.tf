output "url" {
  description = "HTTPS URL of the site."
  value       = module.load_balancer.url
}

output "ip_address" {
  description = "Reserved global IP of the site; it does not change between deployments."
  value       = module.load_balancer.ip_address
}

output "content_sha256" {
  description = "SHA-256 of the rendered page; the smoke test compares it with the page actually served."
  value       = sha256(local.html)
}

output "certificate_name" {
  description = "Managed certificate, to check its provisioning status."
  value       = module.load_balancer.certificate_name
}

output "bucket_name" {
  description = "Bucket that stores the site."
  value       = module.site.bucket_name
}

output "content_md5" {
  description = "MD5 hash of the deployed index.html."
  value       = module.site.content_md5
}
