variable "project_id" {
  description = "ID of the Google Cloud project that hosts this environment."
  type        = string
}

variable "region" {
  description = "Region of the managed instance group."
  type        = string
}

variable "environment" {
  description = "Environment name, shown on the page and used in labels."
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be dev or prod."
  }
}

variable "zones" {
  description = "Zones across which instances are spread."
  type        = list(string)
}

variable "instance_count" {
  description = "Number of instances; at least one per zone."
  type        = number
}

variable "machine_type" {
  description = "Machine type of the instances."
  type        = string

  validation {
    condition     = can(regex("^e2-", var.machine_type))
    error_message = "machine_type must be in the cost-efficient e2 family."
  }
}

variable "web_server_image" {
  description = "Docker Hub image of the web server, pinned by digest. It is pulled through the Artifact Registry mirror."
  type        = string
  default     = "nginxinc/nginx-unprivileged:stable-alpine@sha256:ed04ec1ff34502c339ee5c3ae3f855442398edc1d05591e2b98981dcbbd20b1e"
}

variable "domain" {
  description = "Hostname of the site. When null, it is derived from the reserved IP with sslip.io."
  type        = string
  default     = null
}
