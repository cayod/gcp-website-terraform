locals {
  site_key = "mig"

  labels = {
    environment = var.environment
    managed-by  = "terraform"
    site        = local.site_key
  }

  # Naming convention of the foundation layer: one state bucket per project.
  foundation_state_bucket = "${var.project_id}-tfstate"
  foundation              = data.terraform_remote_state.foundation.outputs

  html = templatefile("${path.module}/../../site/index.html", {
    environment = var.environment
    approach    = "Managed Instance Group"
  })
}

data "terraform_remote_state" "foundation" {
  backend = "gcs"

  config = {
    bucket = local.foundation_state_bucket
    prefix = "foundation"
  }
}

module "site" {
  source = "../../modules/site-mig"

  name                  = "site-${local.site_key}"
  region                = var.region
  zones                 = var.zones
  instance_count        = var.instance_count
  machine_type          = var.machine_type
  subnetwork_id         = local.foundation.subnetwork_id
  network_tag           = local.foundation.web_network_tag
  port                  = local.foundation.web_port
  service_account_email = local.foundation.web_vm_service_account_email
  container_image       = "${local.foundation.docker_hub_mirror}/${var.web_server_image}"
  html                  = local.html
}

module "load_balancer" {
  source = "../../modules/https-lb"

  name       = "site-${local.site_key}"
  ip_address = local.foundation.site_addresses[local.site_key].address
  backend_id = module.site.backend_id
  domain     = var.domain
}
