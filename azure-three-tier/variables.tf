variable "name" {
  description = "Base name for the deployment. Lowercase letters, digits and hyphens, 2 to 20 characters."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,19}$", var.name))
    error_message = "name must be 2 to 20 characters of lowercase letters, digits and hyphens, starting with a letter or digit."
  }
}

variable "resource_group_name" {
  description = "Resource group the template creates for this deployment. Remove deletes it with everything in it."
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9._()-]{1,90}$", var.resource_group_name))
    error_message = "resource_group_name must be 1 to 90 characters of letters, digits, periods, underscores, hyphens or parentheses."
  }
}

variable "location" {
  description = "Azure region code, for example uksouth. OneCloud fills it from the account region when the variable mapping says so."
  type        = string
  default     = "uksouth"
}

variable "address_space" {
  description = "Address space of the virtual network in CIDR notation."
  type        = string
  default     = "10.70.0.0/16"

  validation {
    condition     = can(cidrhost(var.address_space, 0))
    error_message = "address_space must be a valid CIDR block."
  }
}

variable "web_subnet_prefix" {
  description = "Address prefix of the web subnet."
  type        = string
  default     = "10.70.1.0/24"

  validation {
    condition     = can(cidrhost(var.web_subnet_prefix, 0))
    error_message = "web_subnet_prefix must be a valid CIDR block."
  }
}

variable "app_subnet_prefix" {
  description = "Address prefix of the app subnet."
  type        = string
  default     = "10.70.2.0/24"

  validation {
    condition     = can(cidrhost(var.app_subnet_prefix, 0))
    error_message = "app_subnet_prefix must be a valid CIDR block."
  }
}

variable "ingress_ports" {
  description = "TCP ports the web tier accepts from ingress_source_cidr."
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

variable "web_vm_size" {
  description = "Size of the web server."
  type        = string
  default     = "Standard_B1s"

  validation {
    condition     = contains(["Standard_B1s", "Standard_B1ms", "Standard_B2s"], var.web_vm_size)
    error_message = "web_vm_size must be Standard_B1s, Standard_B1ms or Standard_B2s."
  }
}

variable "app_vm_size" {
  description = "Size of the app server."
  type        = string
  default     = "Standard_B1s"

  validation {
    condition     = contains(["Standard_B1s", "Standard_B1ms", "Standard_B2s"], var.app_vm_size)
    error_message = "app_vm_size must be Standard_B1s, Standard_B1ms or Standard_B2s."
  }
}

variable "web_os_disk_size_gb" {
  description = "Operating system disk size of the web server in GB. It can grow, never shrink."
  type        = number
  default     = 30

  validation {
    condition     = var.web_os_disk_size_gb >= 30 && var.web_os_disk_size_gb <= 1024
    error_message = "web_os_disk_size_gb must be from 30 to 1024."
  }
}

variable "app_os_disk_size_gb" {
  description = "Operating system disk size of the app server in GB. It can grow, never shrink."
  type        = number
  default     = 30

  validation {
    condition     = var.app_os_disk_size_gb >= 30 && var.app_os_disk_size_gb <= 1024
    error_message = "app_os_disk_size_gb must be from 30 to 1024."
  }
}

variable "app_data_disk_sizes_gb" {
  description = "Sizes in GB of the managed data disks on the app server, one entry per disk. Add to the end of the list only."
  type        = list(number)
  default     = [8]

  validation {
    condition     = alltrue([for s in var.app_data_disk_sizes_gb : s >= 4 && s <= 4095]) && length(var.app_data_disk_sizes_gb) <= 4
    error_message = "app_data_disk_sizes_gb must hold up to 4 sizes from 4 to 4095."
  }
}

variable "admin_username" {
  description = "Administrator account on both servers. Azure rejects reserved names such as root, admin and administrator."
  type        = string
  default     = "azureuser"

  validation {
    condition     = can(regex("^[a-z_][a-z0-9_-]{0,31}$", var.admin_username)) && !contains(["root", "admin", "administrator", "test", "user", "guest"], var.admin_username)
    error_message = "admin_username must be 1 to 32 lowercase characters and not a name Azure reserves (root, admin, administrator, test, user, guest)."
  }
}

variable "ssh_public_key" {
  description = "OpenSSH public key for the administrator account, the single line that starts with ssh-ed25519 or ssh-rsa."
  type        = string

  validation {
    condition     = can(regex("^(ssh-ed25519|ssh-rsa|ecdsa-sha2-nistp256) [A-Za-z0-9+/=]+", var.ssh_public_key))
    error_message = "ssh_public_key must be an OpenSSH public key line (ssh-ed25519, ssh-rsa or ecdsa-sha2-nistp256 followed by the key material)."
  }
}

variable "test_tag" {
  description = "Value of the OneCloudTest tag put on every resource, so a test can find and remove what it made. Leave empty outside tests."
  type        = string
  default     = ""

  validation {
    condition     = can(regex("^[A-Za-z0-9._-]{0,64}$", var.test_tag))
    error_message = "test_tag must be up to 64 letters, digits, periods, underscores or hyphens."
  }
}

variable "tags" {
  description = "Tags applied to every resource. OneCloud passes the deployment tags here, including the onecloud_deployment correlation tag."
  type        = map(string)
  default     = {}
}

# Database tier, not active yet. Uncomment these two variables together with the database block at the end of main.tf.
# The names match what the OneCloud operations Change database size (db_sku_name) and Grow database storage
# (db_storage_gb) bind to.
#
# variable "db_sku_name" {
#   description = "Size of the PostgreSQL flexible server."
#   type        = string
#   default     = "B_Standard_B1ms"
#
#   validation {
#     condition     = contains(["B_Standard_B1ms", "B_Standard_B2s", "GP_Standard_D2s_v3"], var.db_sku_name)
#     error_message = "db_sku_name must be B_Standard_B1ms, B_Standard_B2s or GP_Standard_D2s_v3."
#   }
# }
#
# variable "db_storage_gb" {
#   description = "Storage of the PostgreSQL flexible server in GB. It can grow, never shrink."
#   type        = number
#   default     = 32
#
#   validation {
#     condition     = contains([32, 64, 128, 256, 512, 1024], var.db_storage_gb)
#     error_message = "db_storage_gb must be 32, 64, 128, 256, 512 or 1024."
#   }
# }
