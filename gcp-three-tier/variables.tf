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
  description = "Google Cloud region, for example europe-west2. OneCloudify fills it from the region picked on the order."
  type        = string
  default     = "europe-west2"

  validation {
    condition     = can(regex("^[a-z]+-[a-z]+[0-9]{1,2}$", var.region))
    error_message = "region must be a Google Cloud region such as europe-west2."
  }
}

variable "zone_suffix" {
  description = "Zone letter inside the region for both servers and the data disks, for example a for europe-west2-a."
  type        = string
  default     = "a"

  validation {
    condition     = contains(["a", "b", "c", "d", "f"], var.zone_suffix)
    error_message = "zone_suffix must be a, b, c, d or f."
  }
}

variable "name" {
  description = "Base name for the deployment. Lowercase letters, digits and hyphens, 2 to 24 characters, starting with a letter."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,23}$", var.name))
    error_message = "name must be 2 to 24 characters of lowercase letters, digits and hyphens, starting with a letter."
  }
}

variable "web_subnet_cidr" {
  description = "Address range of the web subnet."
  type        = string
  default     = "10.90.1.0/24"

  validation {
    condition     = can(cidrhost(var.web_subnet_cidr, 0))
    error_message = "web_subnet_cidr must be a valid CIDR block."
  }
}

variable "app_subnet_cidr" {
  description = "Address range of the app subnet."
  type        = string
  default     = "10.90.2.0/24"

  validation {
    condition     = can(cidrhost(var.app_subnet_cidr, 0))
    error_message = "app_subnet_cidr must be a valid CIDR block."
  }
}

variable "ingress_ports" {
  description = "TCP ports the web tier accepts from ingress_source_cidr. Each port is its own firewall rule."
  type        = list(number)
  default     = [80, 443]

  validation {
    condition     = alltrue([for p in var.ingress_ports : p >= 1 && p <= 65535]) && length(var.ingress_ports) <= 50
    error_message = "ingress_ports must hold up to 50 port numbers from 1 to 65535."
  }
}

variable "ingress_source_cidr" {
  description = "Where the web tier ports may be reached from, a CIDR block. 0.0.0.0/0 means anywhere."
  type        = string
  default     = "0.0.0.0/0"

  validation {
    condition     = can(cidrhost(var.ingress_source_cidr, 0))
    error_message = "ingress_source_cidr must be a valid CIDR block."
  }
}

variable "app_port" {
  description = "TCP port of the app tier, reachable from the web servers only."
  type        = number
  default     = 8080

  validation {
    condition     = var.app_port >= 1 && var.app_port <= 65535
    error_message = "app_port must be from 1 to 65535."
  }
}

variable "web_machine_type" {
  description = "Machine type of the web server."
  type        = string
  default     = "e2-micro"

  validation {
    condition     = contains(["e2-micro", "e2-small", "e2-medium", "n2-standard-2"], var.web_machine_type)
    error_message = "web_machine_type must be e2-micro, e2-small, e2-medium or n2-standard-2."
  }
}

variable "app_machine_type" {
  description = "Machine type of the app server."
  type        = string
  default     = "e2-micro"

  validation {
    condition     = contains(["e2-micro", "e2-small", "e2-medium", "n2-standard-2"], var.app_machine_type)
    error_message = "app_machine_type must be e2-micro, e2-small, e2-medium or n2-standard-2."
  }
}

variable "web_boot_disk_size" {
  description = "Boot disk size of the web server in GB. It can grow, never shrink."
  type        = number
  default     = 10

  validation {
    condition     = var.web_boot_disk_size >= 10 && var.web_boot_disk_size <= 100
    error_message = "web_boot_disk_size must be from 10 to 100."
  }
}

variable "app_boot_disk_size" {
  description = "Boot disk size of the app server in GB. It can grow, never shrink."
  type        = number
  default     = 10

  validation {
    condition     = var.app_boot_disk_size >= 10 && var.app_boot_disk_size <= 100
    error_message = "app_boot_disk_size must be from 10 to 100."
  }
}

variable "app_data_disk_sizes_gb" {
  description = "Sizes in GB of the persistent data disks on the app server, one entry per disk. Add to the end of the list only."
  type        = list(number)
  default     = [10]

  validation {
    condition     = alltrue([for s in var.app_data_disk_sizes_gb : s >= 10 && s <= 100]) && length(var.app_data_disk_sizes_gb) <= 4
    error_message = "app_data_disk_sizes_gb must hold up to 4 sizes from 10 to 100."
  }
}

variable "disk_type" {
  description = "Persistent disk type of the boot and data disks: pd-balanced (default), pd-standard or pd-ssd."
  type        = string
  default     = "pd-balanced"

  validation {
    condition     = contains(["pd-balanced", "pd-standard", "pd-ssd"], var.disk_type)
    error_message = "disk_type must be pd-balanced, pd-standard or pd-ssd."
  }
}

variable "ssh_public_key" {
  description = "Optional OpenSSH public key for the user onecloud on both servers. Leave empty to sign in through IAP or OS Login instead."
  type        = string
  default     = ""

  validation {
    condition     = var.ssh_public_key == "" || can(regex("^(ssh-ed25519|ssh-rsa|ecdsa-sha2-nistp256) [A-Za-z0-9+/=]+", var.ssh_public_key))
    error_message = "ssh_public_key must be empty or an OpenSSH public key line."
  }
}

variable "test_tag" {
  description = "Value of the onecloudtest label put on every resource, so a test can find and remove what it made. Leave empty outside tests."
  type        = string
  default     = ""

  validation {
    condition     = can(regex("^[a-z0-9_-]{0,63}$", var.test_tag))
    error_message = "test_tag must be up to 63 lowercase letters, digits, underscores or hyphens (a Google label value)."
  }
}

variable "cost_centre" {
  description = "Cost centre the resources are charged to, put on every resource as the cost_centre label (in lower case, as Google labels require)."
  type        = string
  default     = "CC-1001"

  validation {
    condition     = can(regex("^[A-Za-z0-9-]{1,20}$", var.cost_centre))
    error_message = "cost_centre must be 1 to 20 letters, digits or hyphens."
  }
}

variable "tags" {
  description = "Tags applied to every resource as Google labels. OneCloudify passes the deployment tags here, including the onecloud_deployment correlation tag. Keys and values are put in lower case and other characters become underscores, as Google labels require."
  type        = map(string)
  default     = {}
}
