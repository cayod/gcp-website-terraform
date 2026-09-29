variable "name" {
  description = "Name of the backend bucket."
  type        = string
}

variable "bucket_name" {
  description = "Globally unique name of the bucket that stores the site."
  type        = string
}

variable "location" {
  description = "Location of the site bucket."
  type        = string
}

variable "html" {
  description = "Content of index.html. Any change is uploaded and served on the next request."
  type        = string

  validation {
    condition     = length(trimspace(var.html)) > 0
    error_message = "html must not be empty."
  }
}

variable "cdn_default_ttl_seconds" {
  description = "Cache lifetime at the edge for static assets that send no caching headers."
  type        = number
  default     = 3600
}
