locals {
  web_network_tag = "web"
  web_port        = 80

  # Source ranges of Google Front Ends: load balancer traffic and health checks.
  google_front_end_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
}

resource "google_compute_network" "web" {
  name                    = "web"
  auto_create_subnetworks = false

  depends_on = [google_project_service.required]
}

# Private Google Access lets VMs without external IPs pull images from Artifact Registry.
resource "google_compute_subnetwork" "web" {
  name                     = "web-${var.region}"
  network                  = google_compute_network.web.id
  region                   = var.region
  ip_cidr_range            = var.subnet_cidr
  private_ip_google_access = true

  # Sampled flow logs give visibility on unexpected traffic at a negligible cost for this volume.
  log_config {
    aggregation_interval = "INTERVAL_5_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_firewall" "allow_google_front_ends" {
  name          = "web-allow-google-front-ends"
  network       = google_compute_network.web.id
  direction     = "INGRESS"
  source_ranges = local.google_front_end_ranges
  target_tags   = [local.web_network_tag]

  allow {
    protocol = "tcp"
    ports    = [tostring(local.web_port)]
  }
}

resource "google_compute_global_address" "site" {
  for_each = local.sites

  name       = "site-${each.key}"
  ip_version = "IPV4"

  depends_on = [google_project_service.required]
}
