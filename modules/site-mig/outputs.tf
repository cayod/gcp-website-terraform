output "backend_id" {
  description = "ID of the backend service, to route load balancer traffic to."
  value       = google_compute_backend_service.this.id
}

output "instance_group_manager" {
  description = "Name of the managed instance group."
  value       = google_compute_region_instance_group_manager.this.name
}

output "instance_template" {
  description = "Instance template currently rolled out; it changes on every redeployment."
  value       = google_compute_instance_template.this.name
}
