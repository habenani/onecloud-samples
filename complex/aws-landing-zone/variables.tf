# Core inputs of the landing zone. More variables live in network.tf, security.tf and extra-variables.tf:
# Terraform reads every *.tf file in the folder, so a variable can sit in any of them.

variable "name" {
  description = "Short name of the landing zone. Lower case letters, digits and hyphens, 3 to 24 characters."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,23}$", var.name))
    error_message = "Use 3 to 24 lower case letters, digits or hyphens, starting with a letter."
  }
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-north-1"
}

variable "environment" {
  description = "Environment"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "Environment must be dev, test or prod."
  }
}

variable "project_code" {
  description = "Project code"
  type        = string
  default     = "PRJ-0001"

  validation {
    condition     = can(regex("^PRJ-[0-9]{4}$", var.project_code))
    error_message = "The project code looks like PRJ-1234."
  }

  validation {
    condition     = length(var.project_code) == 8
    error_message = "The project code is exactly 8 characters."
  }
}

variable "owner_email" {
  description = <<-EOT
    Email address of the **owning team**.

    - Used for the `owner` tag on every resource.
    - Must be a shared mailbox, not a person.
  EOT
  type        = string
  default     = "platform-team@example.com"

  validation {
    condition     = can(regex("^[^@\\s]+@[^@\\s]+\\.[a-z]{2,}$", var.owner_email))
    error_message = "Enter a valid email address."
  }
}

variable "cost_centre" {
  description = "Cost centre code, if the team has one"
  type        = string
  default     = null
}

variable "log_retention_days" {
  description = "Days to keep logs"
  type        = number
  default     = 7

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90], var.log_retention_days)
    error_message = "Pick one of the retention periods CloudWatch supports: 1, 3, 5, 7, 14, 30, 60 or 90."
  }
}

variable "lifecycle_days" {
  description = "Days before old object versions are deleted (1 to 365, whole days)"
  type        = number
  default     = 30

  validation {
    condition     = var.lifecycle_days >= 1 && var.lifecycle_days <= 365
    error_message = "Use a number from 1 to 365."
  }

  validation {
    condition     = floor(var.lifecycle_days) == var.lifecycle_days
    error_message = "Use whole days."
  }
}

variable "enable_versioning" {
  description = "Keep old versions of objects in the bucket"
  type        = bool
  default     = true
}

variable "force_destroy" {
  description = "Delete the bucket even when it still holds objects"
  type        = bool
  default     = true
  nullable    = false
}

variable "app_secret" {
  description = "Secret the application reads at start up. Stored as a hash only."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.app_secret) >= 12
    error_message = "The secret needs at least 12 characters."
  }
}

/*
  An ephemeral variable (Terraform 1.10 and later) is never written to the plan or the state.
  It may only be used in places that are ephemeral too, here a local value.
*/
variable "api_token" {
  description = "Optional token for the deployment pipeline"
  type        = string
  default     = null
  sensitive   = true
  ephemeral   = true
}

variable "tags" {
  description = "Tags applied by OneCloud"
  type        = map(string)
  default     = {}
}
