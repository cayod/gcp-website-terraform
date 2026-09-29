variable "name" {
  description = "Prefix for the names of the MIG resources."
  type        = string
}

variable "region" {
  description = "Region of the managed instance group."
  type        = string
}

variable "zones" {
  description = "Zones across which instances are spread."
  type        = list(string)

  validation {
    condition     = length(var.zones) > 0
    error_message = "zones must contain at least one zone."
  }
}

variable "instance_count" {
  description = "Number of instances; at least one per zone."
  type        = number

  validation {
    condition     = var.instance_count >= length(var.zones)
    error_message = "instance_count must be at least the number of zones, so every zone serves traffic."
  }
}

variable "machine_type" {
  description = "Machine type of the instances."
  type        = string
  default     = "e2-micro"
}

variable "subnetwork_id" {
  description = "Subnet of the instances; it must have Private Google Access."
  type        = string
}

variable "network_tag" {
  description = "Network tag allowed by the firewall to receive load balancer traffic."
  type        = string
}

variable "port" {
  description = "Host port that serves HTTP traffic and health checks."
  type        = number
}

variable "service_account_email" {
  description = "Dedicated identity of the instances."
  type        = string
}

variable "container_image" {
  description = "Web server image, pinned by digest so every instance runs the same build."
  type        = string

  validation {
    condition     = can(regex("@sha256:[a-f0-9]{64}$", var.container_image))
    error_message = "container_image must be pinned by digest (image@sha256:...)."
  }
}

variable "container_port" {
  description = "Port the web server listens on inside the container."
  type        = number
  default     = 8080
}

variable "html" {
  description = "Content of index.html. A change creates a new instance template and a rolling update."
  type        = string

  validation {
    condition     = length(trimspace(var.html)) > 0
    error_message = "html must not be empty."
  }
}
