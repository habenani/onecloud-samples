variable "project" {
  description = "Google Cloud project id. Leave empty to use the project of the OneCloudify cloud account (GOOGLE_PROJECT)."
  type        = string
  default     = ""

  validation {
    condition     = var.project == "" || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project))
    error_message = "project must be empty or a Google Cloud project id (6 to 30 lowercase letters, digits and hyphens)."
  }
}

variable "region" {
  description = "Google Cloud region, for example us-central1. OneCloudify fills it from the region picked on the order."
  type        = string
  default     = "us-central1"

  validation {
    condition     = can(regex("^[a-z]+-[a-z]+[0-9]{1,2}$", var.region))
    error_message = "region must be a Google Cloud region such as us-central1."
  }
}

variable "zone_suffix" {
  description = "Zone letter inside the region, for example a for us-central1-a."
  type        = string
  default     = "a"

  validation {
    condition     = contains(["a", "b", "c", "d", "f"], var.zone_suffix)
    error_message = "zone_suffix must be a, b, c, d or f."
  }
}

variable "name" {
  description = "Name of the server. Lowercase letters, digits and hyphens, 2 to 30 characters, starting with a letter."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,29}$", var.name))
    error_message = "name must be 2 to 30 characters of lowercase letters, digits and hyphens, starting with a letter."
  }
}

variable "machine_type" {
  description = "Machine type. e2-micro is in the Always Free tier in us-west1, us-central1 and us-east1."
  type        = string
  default     = "e2-micro"

  validation {
    condition     = contains(["e2-micro", "e2-small", "e2-medium"], var.machine_type)
    error_message = "machine_type must be e2-micro, e2-small or e2-medium."
  }
}

variable "boot_disk_size" {
  description = "Boot disk size in GB (standard persistent disk). It can grow, never shrink."
  type        = number
  default     = 10

  validation {
    condition     = var.boot_disk_size >= 10 && var.boot_disk_size <= 100
    error_message = "boot_disk_size must be from 10 to 100."
  }
}

variable "subnet_cidr" {
  description = "Address range of the subnet."
  type        = string
  default     = "10.92.1.0/24"

  validation {
    condition     = can(cidrhost(var.subnet_cidr, 0))
    error_message = "subnet_cidr must be a valid CIDR block."
  }
}
