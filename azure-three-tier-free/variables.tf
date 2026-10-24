variable "name" {
  description = "Name of the deployment, used in every resource name, for example shop-3t-uks-01"
  type        = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,20}$", var.name))
    error_message = "Use 3 to 21 lower case letters, digits and hyphens, starting with a letter"
  }
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "uksouth"
}

variable "vm_size" {
  description = "Size of the web server. Standard_B1s is in the Azure free services for 12 months"
  type        = string
  default     = "Standard_B1s"
  validation {
    condition     = contains(["Standard_B1s", "Standard_B1ms", "Standard_B2s"], var.vm_size)
    error_message = "Choose Standard_B1s, Standard_B1ms or Standard_B2s"
  }
}

variable "os_disk_type" {
  description = "Disk type of the web server"
  type        = string
  default     = "StandardSSD_LRS"
  validation {
    condition     = contains(["Standard_LRS", "StandardSSD_LRS", "Premium_LRS"], var.os_disk_type)
    error_message = "Choose Standard_LRS, StandardSSD_LRS or Premium_LRS"
  }
}

variable "os_disk_size_gb" {
  description = "Disk size of the web server in GB, 30 to 64"
  type        = number
  default     = 30
  validation {
    condition     = var.os_disk_size_gb >= 30 && var.os_disk_size_gb <= 64
    error_message = "Use 30 to 64 GB"
  }
}

variable "db_sku" {
  description = "Size of the PostgreSQL database server. B_Standard_B1ms is in the Azure free services for 12 months"
  type        = string
  default     = "B_Standard_B1ms"
  validation {
    condition     = contains(["B_Standard_B1ms", "B_Standard_B2s"], var.db_sku)
    error_message = "Choose B_Standard_B1ms or B_Standard_B2s"
  }
}

variable "db_storage_mb" {
  description = "Database storage in MB. 32768 (32 GB) is in the Azure free services"
  type        = number
  default     = 32768
  validation {
    condition     = contains([32768, 65536], var.db_storage_mb)
    error_message = "Choose 32768 or 65536"
  }
}

variable "db_admin_password" {
  description = "Password of the database administrator, 12 to 64 characters with upper and lower case letters and digits"
  type        = string
  sensitive   = true
  validation {
    condition     = length(var.db_admin_password) >= 12 && length(var.db_admin_password) <= 64
    error_message = "Use 12 to 64 characters"
  }
}

variable "ssh_public_key" {
  description = "Public SSH key of the web server administrator, for example ssh-ed25519 AAAA... or ssh-rsa AAAA..."
  type        = string
}

variable "tags" {
  description = "Tags applied by OneCloudify"
  type        = map(string)
  default     = {}
}
