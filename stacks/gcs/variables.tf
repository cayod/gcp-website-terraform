variable "project_id" {
  description = "ID of the Google Cloud project that hosts this environment."
  type        = string
}

variable "region" {
  description = "Region of the site bucket."
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

variable "domain" {
  description = "Hostname of the site. When null, it is derived from the reserved IP with sslip.io."
  type        = string
  default     = null
}
