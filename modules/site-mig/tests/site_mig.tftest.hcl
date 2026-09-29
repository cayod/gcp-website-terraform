mock_provider "google" {}
mock_provider "google-beta" {}

variables {
  name                  = "site-test"
  region                = "us-central1"
  zones                 = ["us-central1-a", "us-central1-b"]
  instance_count        = 2
  machine_type          = "e2-micro"
  subnetwork_id         = "projects/demo/regions/us-central1/subnetworks/web"
  network_tag           = "web"
  port                  = 80
  service_account_email = "web-vm@demo.iam.gserviceaccount.com"
  container_image       = "us-central1-docker.pkg.dev/demo/dockerhub/nginxinc/nginx-unprivileged:stable-alpine@sha256:ed04ec1ff34502c339ee5c3ae3f855442398edc1d05591e2b98981dcbbd20b1e"
  html                  = "<!doctype html><title>test</title>"
}

run "vms_have_no_external_ip" {
  command = plan

  assert {
    condition     = length(google_compute_instance_template.this.network_interface[0].access_config) == 0
    error_message = "VMs must not have an external IP; the load balancer is the only entry point."
  }
}

run "vms_run_with_the_dedicated_identity" {
  command = plan

  assert {
    condition     = google_compute_instance_template.this.service_account[0].email == var.service_account_email
    error_message = "VMs must run as the dedicated service account, never the Compute Engine default."
  }
}

run "vms_are_hardened" {
  command = plan

  assert {
    condition     = google_compute_instance_template.this.shielded_instance_config[0].enable_secure_boot == true
    error_message = "Secure Boot must be enabled."
  }

  assert {
    condition     = google_compute_instance_template.this.metadata["block-project-ssh-keys"] == "true"
    error_message = "Project-wide SSH keys must be blocked."
  }
}

run "vms_are_reachable_by_the_load_balancer_firewall" {
  command = plan

  assert {
    condition     = contains(google_compute_instance_template.this.tags, var.network_tag)
    error_message = "VMs must carry the tag allowed by the firewall."
  }
}

run "html_change_produces_a_new_template" {
  command = plan

  assert {
    condition     = strcontains(google_compute_instance_template.this.metadata["user-data"], base64encode(var.html))
    error_message = "The HTML must be part of the template, so a change triggers a rolling update."
  }

  assert {
    condition     = strcontains(google_compute_instance_template.this.metadata["user-data"], var.container_image)
    error_message = "The pinned container image must be the one started on the VM."
  }
}

run "rolling_update_keeps_the_site_available" {
  command = plan

  assert {
    condition     = google_compute_region_instance_group_manager.this.update_policy[0].type == "PROACTIVE"
    error_message = "A new template must be rolled out automatically."
  }

  assert {
    condition     = google_compute_region_instance_group_manager.this.update_policy[0].max_unavailable_fixed == 0 && google_compute_region_instance_group_manager.this.update_policy[0].max_surge_fixed == length(var.zones)
    error_message = "New instances must be created before old ones are removed."
  }
}

run "rolling_update_waits_for_the_load_balancer" {
  command = plan

  assert {
    condition = google_compute_region_instance_group_manager.this.update_policy[0].min_ready_sec > (
      google_compute_health_check.this.healthy_threshold * google_compute_health_check.this.check_interval_sec
    )
    error_message = "A new instance must stay ready longer than the load balancer needs to mark it healthy before an old one is removed."
  }
}

run "mig_heals_and_spreads_instances" {
  command = plan

  assert {
    condition     = google_compute_region_instance_group_manager.this.target_size == var.instance_count
    error_message = "The MIG must run the requested number of instances."
  }

  assert {
    condition     = toset(google_compute_region_instance_group_manager.this.distribution_policy_zones) == toset(var.zones)
    error_message = "Instances must be spread across the requested zones."
  }

  assert {
    condition     = length(google_compute_region_instance_group_manager.this.auto_healing_policies) == 1
    error_message = "Unhealthy instances must be recreated."
  }
}

run "backend_is_served_by_the_global_external_load_balancer" {
  command = plan

  assert {
    condition     = google_compute_backend_service.this.load_balancing_scheme == "EXTERNAL_MANAGED" && google_compute_backend_service.this.port_name == "http"
    error_message = "The backend service must belong to the global external Application Load Balancer."
  }
}

run "rejects_an_image_without_digest" {
  command = plan

  variables {
    container_image = "nginx:latest"
  }

  expect_failures = [var.container_image]
}

run "rejects_fewer_instances_than_zones" {
  command = plan

  variables {
    instance_count = 1
  }

  expect_failures = [var.instance_count]
}
