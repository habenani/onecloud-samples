variable "name" {
  description = "Base name for the virtual machine and its network objects. Lowercase letters, digits and hyphens, 2 to 32 characters."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,31}$", var.name))
    error_message = "name must be 2 to 32 characters of lowercase letters, digits and hyphens, starting with a letter or digit."
  }
}

variable "location" {
  description = "Azure region code, for example uksouth or westeurope. OneCloudify fills this from the selected account region when the variable mapping says so."
  type        = string
  default     = "uksouth"
}

variable "resource_group_name" {
  description = "Resource group that holds the virtual machine. Created when create_resource_group is true, otherwise it must already exist."
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9._()-]{1,90}$", var.resource_group_name))
    error_message = "resource_group_name must be 1 to 90 characters of letters, digits, periods, underscores, hyphens or parentheses."
  }
}

variable "create_resource_group" {
  description = "Create the resource group. Set to false to deploy into an existing one."
  type        = bool
  default     = true
}

variable "create_network" {
  description = "Create a virtual network and subnet for the virtual machine. Set to false to place it in an existing subnet (subnet_id)."
  type        = bool
  default     = true
}

variable "subnet_id" {
  description = "Azure resource id of an existing subnet, used when create_network is false. The subnet must be in the same region."
  type        = string
  default     = ""

  validation {
    condition     = var.subnet_id == "" || can(regex("(?i)^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft.Network/virtualNetworks/[^/]+/subnets/[^/]+$", var.subnet_id))
    error_message = "subnet_id must be empty or the resource id of a subnet (/subscriptions/.../virtualNetworks/<vnet>/subnets/<subnet>)."
  }
}

variable "address_space" {
  description = "Address space of the new virtual network in CIDR notation. Used when create_network is true."
  type        = string
  default     = "10.60.0.0/16"

  validation {
    condition     = can(cidrhost(var.address_space, 0))
    error_message = "address_space must be a valid CIDR block."
  }
}

variable "subnet_prefix" {
  description = "Address prefix of the new subnet, inside the virtual network address space. Used when create_network is true."
  type        = string
  default     = "10.60.1.0/24"

  validation {
    condition     = can(cidrhost(var.subnet_prefix, 0))
    error_message = "subnet_prefix must be a valid CIDR block."
  }
}

variable "ssh_source_cidr" {
  description = "CIDR block allowed to reach the virtual machine on port 22, for example your office range 203.0.113.0/24. Use 0.0.0.0/0 only for a throwaway lab."
  type        = string

  validation {
    condition     = can(cidrhost(var.ssh_source_cidr, 0))
    error_message = "ssh_source_cidr must be a valid CIDR block."
  }
}

variable "create_public_ip" {
  description = "Attach a static public IP address to the virtual machine."
  type        = bool
  default     = true
}

variable "vm_size" {
  description = "Virtual machine size, for example Standard_B1s, Standard_B2s or Standard_D2s_v5."
  type        = string
  default     = "Standard_B1s"

  validation {
    condition     = can(regex("^Standard_[A-Za-z0-9_-]+$", var.vm_size))
    error_message = "vm_size must be an Azure size name such as Standard_B1s."
  }
}

variable "os_disk_type" {
  description = "Storage type of the operating system disk."
  type        = string
  default     = "Standard_LRS"

  validation {
    condition     = contains(["Standard_LRS", "StandardSSD_LRS", "Premium_LRS"], var.os_disk_type)
    error_message = "os_disk_type must be Standard_LRS, StandardSSD_LRS or Premium_LRS."
  }
}

variable "admin_username" {
  description = "Administrator account on the virtual machine. Azure rejects reserved names such as root, admin and administrator."
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

variable "tags" {
  description = "Tags applied to every resource. OneCloudify passes the deployment tags here, including the onecloud_deployment correlation tag."
  type        = map(string)
  default     = {}
}
