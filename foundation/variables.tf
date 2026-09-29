variable "project_id" {
  description = "ID of the existing Google Cloud project that hosts this environment."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "project_id must be a valid Google Cloud project ID."
  }
}

variable "region" {
  description = "Region for regional resources: state bucket, subnet, and Artifact Registry repository."
  type        = string
}

variable "environment" {
  description = "Environment name, used in labels and to bind the CI identity to a GitHub Environment."
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be dev or prod."
  }
}

variable "subnet_cidr" {
  description = "Primary IP range of the subnet that hosts the web VMs."
  type        = string
  default     = "10.10.0.0/24"

  validation {
    condition     = can(cidrhost(var.subnet_cidr, 0))
    error_message = "subnet_cidr must be a valid IPv4 CIDR block."
  }
}

variable "github_repository" {
  description = "GitHub repository allowed to deploy, in owner/name form."
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9-]+/[A-Za-z0-9._-]+$", var.github_repository))
    error_message = "github_repository must be in owner/name form."
  }
}

variable "github_repository_id" {
  description = "Numeric ID of the GitHub repository. Unlike the name, it cannot be reused by another repository."
  type        = string

  validation {
    condition     = can(regex("^[0-9]+$", var.github_repository_id))
    error_message = "github_repository_id must be numeric."
  }
}

variable "github_owner_id" {
  description = "Numeric ID of the GitHub repository owner, part of the immutable OIDC subject claim."
  type        = string

  validation {
    condition     = can(regex("^[0-9]+$", var.github_owner_id))
    error_message = "github_owner_id must be numeric."
  }
}

variable "billing_account" {
  description = "Billing account ID used for the budget alert. Leave null to skip the budget."
  type        = string
  default     = null

  validation {
    condition     = var.billing_account == null || can(regex("^[A-Z0-9]{6}-[A-Z0-9]{6}-[A-Z0-9]{6}$", var.billing_account))
    error_message = "billing_account must look like XXXXXX-XXXXXX-XXXXXX."
  }
}

variable "budget_amount" {
  description = "Monthly budget in the currency of the billing account."
  type        = number
  default     = 50

  validation {
    condition     = var.budget_amount > 0
    error_message = "budget_amount must be positive."
  }
}
