locals {
  site_key = "gcs"

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
    approach    = "Cloud Storage + Cloud CDN"
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
  source = "../../modules/site-gcs"

  name        = "site-${local.site_key}"
  bucket_name = "${var.project_id}-site"
  location    = var.region
  html        = local.html
}

module "load_balancer" {
  source = "../../modules/https-lb"

  name       = "site-${local.site_key}"
  ip_address = local.foundation.site_addresses[local.site_key].address
  backend_id = module.site.backend_id
  domain     = var.domain
}
