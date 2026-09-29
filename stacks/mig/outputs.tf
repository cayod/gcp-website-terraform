output "url" {
  description = "HTTPS URL of the site."
  value       = module.load_balancer.url
}

output "ip_address" {
  description = "Reserved global IP of the site; it does not change between deployments."
  value       = module.load_balancer.ip_address
}

output "certificate_name" {
  description = "Managed certificate, to check its provisioning status."
  value       = module.load_balancer.certificate_name
}

output "instance_group_manager" {
  description = "Managed instance group that serves the site."
  value       = module.site.instance_group_manager
}

output "instance_template" {
  description = "Instance template currently rolled out."
  value       = module.site.instance_template
}
