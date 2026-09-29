variable "name" {
  description = "Prefix for the names of the load balancer resources."
  type        = string

  validation {
    condition     = can(regex("^[a-z]([a-z0-9-]{0,40}[a-z0-9])?$", var.name))
    error_message = "name must be a lowercase RFC 1035 label of at most 42 characters."
  }
}

variable "ip_address" {
  description = "Reserved global IPv4 address that serves HTTP and HTTPS."
  type        = string

  validation {
    condition     = can(cidrhost("${var.ip_address}/32", 0))
    error_message = "ip_address must be a valid IPv4 address."
  }
}

variable "backend_id" {
  description = "ID of the backend bucket or backend service that receives HTTPS traffic."
  type        = string
}

variable "domain" {
  description = "Hostname of the site. When null, it is derived from the IP with sslip.io."
  type        = string
  default     = null
}
