locals {
  hostname = coalesce(var.domain, "${replace(var.ip_address, ".", "-")}.sslip.io")

  # Global external Application Load Balancer (the current generation, with Envoy-based proxies).
  load_balancing_scheme = "EXTERNAL_MANAGED"
}

# Managed certificate domains are immutable, so the name carries a hash of the hostname and
# a new certificate is created before the old one is removed.
resource "google_compute_managed_ssl_certificate" "this" {
  name = "${var.name}-${substr(sha1(local.hostname), 0, 8)}"

  managed {
    domains = [local.hostname]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_ssl_policy" "this" {
  name            = "${var.name}-tls"
  profile         = "MODERN"
  min_tls_version = "TLS_1_2"
}

resource "google_compute_url_map" "https" {
  name            = "${var.name}-https"
  default_service = var.backend_id
}

resource "google_compute_target_https_proxy" "this" {
  name             = "${var.name}-https"
  url_map          = google_compute_url_map.https.id
  ssl_certificates = [google_compute_managed_ssl_certificate.this.id]
  ssl_policy       = google_compute_ssl_policy.this.id
}

resource "google_compute_global_forwarding_rule" "https" {
  name                  = "${var.name}-https"
  ip_address            = var.ip_address
  port_range            = "443"
  target                = google_compute_target_https_proxy.this.id
  load_balancing_scheme = local.load_balancing_scheme
}

resource "google_compute_url_map" "http_redirect" {
  name = "${var.name}-http-redirect"

  default_url_redirect {
    https_redirect         = true
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
    strip_query            = false
  }
}

resource "google_compute_target_http_proxy" "redirect" {
  name    = "${var.name}-http-redirect"
  url_map = google_compute_url_map.http_redirect.id
}

resource "google_compute_global_forwarding_rule" "http" {
  name                  = "${var.name}-http"
  ip_address            = var.ip_address
  port_range            = "80"
  target                = google_compute_target_http_proxy.redirect.id
  load_balancing_scheme = local.load_balancing_scheme
}
