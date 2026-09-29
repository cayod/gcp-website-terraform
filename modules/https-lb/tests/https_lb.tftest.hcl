mock_provider "google" {}

variables {
  name       = "site-test"
  ip_address = "203.0.113.10"
  backend_id = "projects/demo/global/backendBuckets/site-test"
}

run "derives_sslip_hostname_from_ip" {
  command = plan

  assert {
    condition     = output.hostname == "203-0-113-10.sslip.io"
    error_message = "Without a domain, the hostname must be derived from the IP with sslip.io."
  }

  assert {
    condition     = tolist(google_compute_managed_ssl_certificate.this.managed[0].domains) == tolist(["203-0-113-10.sslip.io"])
    error_message = "The managed certificate must cover the derived hostname."
  }
}

run "uses_custom_domain_when_given" {
  command = plan

  variables {
    domain = "www.example.com"
  }

  assert {
    condition     = output.hostname == "www.example.com"
    error_message = "A given domain must override the derived hostname."
  }

  assert {
    condition     = output.url == "https://www.example.com"
    error_message = "The URL must use HTTPS and the given domain."
  }
}

run "serves_https_and_http_on_the_reserved_ip" {
  command = plan

  assert {
    condition     = google_compute_global_forwarding_rule.https.ip_address == var.ip_address && google_compute_global_forwarding_rule.https.port_range == "443"
    error_message = "HTTPS must be served on port 443 of the reserved IP."
  }

  assert {
    condition     = google_compute_global_forwarding_rule.http.ip_address == var.ip_address && google_compute_global_forwarding_rule.http.port_range == "80"
    error_message = "HTTP must be served on port 80 of the same reserved IP."
  }
}

run "redirects_http_to_https_permanently" {
  command = plan

  assert {
    condition     = google_compute_url_map.http_redirect.default_url_redirect[0].https_redirect == true
    error_message = "HTTP requests must be redirected to HTTPS."
  }

  assert {
    condition     = google_compute_url_map.http_redirect.default_url_redirect[0].redirect_response_code == "MOVED_PERMANENTLY_DEFAULT"
    error_message = "The redirect must be permanent."
  }
}

run "routes_https_to_the_backend" {
  command = plan

  assert {
    condition     = google_compute_url_map.https.default_service == var.backend_id
    error_message = "HTTPS traffic must reach the given backend."
  }
}

run "enforces_modern_tls" {
  command = plan

  assert {
    condition     = google_compute_ssl_policy.this.min_tls_version == "TLS_1_2" && google_compute_ssl_policy.this.profile == "MODERN"
    error_message = "The TLS policy must require TLS 1.2 or later with the MODERN profile."
  }
}

run "rejects_an_invalid_ip" {
  command = plan

  variables {
    ip_address = "not-an-ip"
  }

  expect_failures = [var.ip_address]
}
