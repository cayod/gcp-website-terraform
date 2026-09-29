output "state_bucket" {
  description = "Bucket that stores the Terraform state of this environment."
  value       = google_storage_bucket.tfstate.name
}

output "network_id" {
  description = "VPC network of the web VMs."
  value       = google_compute_network.web.id
}

output "subnetwork_id" {
  description = "Subnet of the web VMs, with Private Google Access enabled."
  value       = google_compute_subnetwork.web.id
}

output "web_network_tag" {
  description = "Network tag that the firewall allows from Google Front Ends."
  value       = local.web_network_tag
}

output "web_port" {
  description = "Port on which the web VMs serve traffic and health checks."
  value       = local.web_port
}

output "site_addresses" {
  description = "Reserved global IP per hosting approach, keyed by stack name."
  value = {
    for site, address in google_compute_global_address.site : site => {
      name    = address.name
      address = address.address
    }
  }
}

output "docker_hub_mirror" {
  description = "Registry path that proxies Docker Hub, for example <mirror>/library/nginx."
  value       = "${google_artifact_registry_repository.dockerhub.location}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.dockerhub.repository_id}"
}

output "web_vm_service_account_email" {
  description = "Identity attached to the web VMs."
  value       = google_service_account.web_vm.email
}

output "terraform_plan_service_account_email" {
  description = "Identity impersonated by pull request plans."
  value       = google_service_account.terraform_plan.email
}

output "terraform_apply_service_account_email" {
  description = "Identity impersonated by deployments."
  value       = google_service_account.terraform_apply.email
}

output "workload_identity_provider" {
  description = "Full name of the Workload Identity provider, used by google-github-actions/auth."
  value       = google_iam_workload_identity_pool_provider.github.name
}
