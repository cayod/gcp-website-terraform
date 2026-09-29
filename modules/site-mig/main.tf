locals {
  named_port = "http"

  # The family is resolved when an instance is created, so new COS releases do not
  # create a new template and trigger an unplanned rolling update.
  source_image = "projects/cos-cloud/global/images/family/cos-stable"

  user_data = templatefile("${path.module}/cloud-init.yaml.tftpl", {
    html_base64     = base64encode(var.html)
    registry_host   = split("/", var.container_image)[0]
    container_image = var.container_image
    port            = var.port
    container_port  = var.container_port
  })

  health_check = {
    interval_seconds    = 10
    timeout_seconds     = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  # Time for a new instance to boot, pull the image, and pass its first health checks.
  autohealing_initial_delay_seconds = 180

  # The load balancer probes instances on its own and routes to a new one only after
  # healthy_threshold consecutive successes; the margin covers probe jitter.
  load_balancer_ready_seconds = local.health_check.healthy_threshold * local.health_check.interval_seconds
  rollout_margin_seconds      = 10
  rollout_min_ready_seconds   = local.load_balancer_ready_seconds + local.rollout_margin_seconds
}

resource "google_compute_instance_template" "this" {
  name_prefix  = "${var.name}-"
  machine_type = var.machine_type
  region       = var.region
  tags         = [var.network_tag]

  disk {
    source_image = local.source_image
    disk_type    = "pd-balanced"
    disk_size_gb = 10
    auto_delete  = true
    boot         = true
  }

  # No access_config: instances have no external IP.
  network_interface {
    subnetwork = var.subnetwork_id
  }

  service_account {
    email  = var.service_account_email
    scopes = ["cloud-platform"]
  }

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  metadata = {
    user-data              = local.user_data
    google-logging-enabled = "true"
    block-project-ssh-keys = "true"
    enable-oslogin         = "TRUE"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_health_check" "this" {
  name                = "${var.name}-http"
  check_interval_sec  = local.health_check.interval_seconds
  timeout_sec         = local.health_check.timeout_seconds
  healthy_threshold   = local.health_check.healthy_threshold
  unhealthy_threshold = local.health_check.unhealthy_threshold

  http_health_check {
    port         = var.port
    request_path = "/"
  }
}

# google-beta: update_policy.min_ready_sec is only available in the beta API.
resource "google_compute_region_instance_group_manager" "this" {
  provider = google-beta

  name                      = var.name
  region                    = var.region
  base_instance_name        = var.name
  distribution_policy_zones = var.zones
  target_size               = var.instance_count

  version {
    instance_template = google_compute_instance_template.this.self_link_unique
  }

  named_port {
    name = local.named_port
    port = var.port
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.this.id
    initial_delay_sec = local.autohealing_initial_delay_seconds
  }

  # Surge one instance per zone and never take one away before the load balancer routes to
  # its replacement: an instance healthy for the MIG is not yet healthy for the load balancer.
  update_policy {
    type                  = "PROACTIVE"
    minimal_action        = "REPLACE"
    replacement_method    = "SUBSTITUTE"
    max_surge_fixed       = length(var.zones)
    max_unavailable_fixed = 0
    min_ready_sec         = local.rollout_min_ready_seconds
  }

  # Apply returns only when every instance runs the new template, so CI smoke tests see the new page.
  wait_for_instances        = true
  wait_for_instances_status = "UPDATED"
}

resource "google_compute_backend_service" "this" {
  name                  = var.name
  protocol              = "HTTP"
  port_name             = local.named_port
  load_balancing_scheme = "EXTERNAL_MANAGED"
  health_checks         = [google_compute_health_check.this.id]

  backend {
    group           = google_compute_region_instance_group_manager.this.instance_group
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }

  log_config {
    enable      = true
    sample_rate = 1.0
  }
}
