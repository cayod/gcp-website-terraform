output "hostname" {
  description = "Hostname covered by the managed certificate."
  value       = local.hostname
}

output "url" {
  description = "HTTPS URL of the site."
  value       = "https://${local.hostname}"
}

output "ip_address" {
  description = "Reserved global IP that serves the site."
  value       = var.ip_address
}

output "certificate_name" {
  description = "Name of the managed certificate, to check its provisioning status."
  value       = google_compute_managed_ssl_certificate.this.name
}
