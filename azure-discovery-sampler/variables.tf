variable "name" {
  description = "Base name for every resource. Lowercase letters, digits and hyphens, 2 to 20 characters."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,19}$", var.name))
    error_message = "name must be 2 to 20 characters of lowercase letters, digits and hyphens, starting with a letter."
  }
}

variable "location" {
  description = "Azure region code, for example uksouth. OneCloud fills it from the region picked on the order form."
  type        = string
  default     = "uksouth"
}

variable "new_resource_group_name" {
  description = "New resource group that holds the sampler. Removing the deployment deletes it."
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9._()-]{1,90}$", var.new_resource_group_name))
    error_message = "new_resource_group_name must be 1 to 90 characters of letters, digits, periods, underscores, hyphens or parentheses."
  }
}

variable "ssh_source_cidr" {
  description = "CIDR block allowed to reach the virtual machine on port 22, for example 203.0.113.0/24."
  type        = string
  default     = "203.0.113.0/24"

  validation {
    condition     = can(cidrhost(var.ssh_source_cidr, 0))
    error_message = "ssh_source_cidr must be a valid CIDR block."
  }
}

variable "ssh_public_key" {
  description = "OpenSSH public key for the virtual machine administrator, the single line that starts with ssh-ed25519 or ssh-rsa."
  type        = string

  validation {
    condition     = can(regex("^(ssh-ed25519|ssh-rsa|ecdsa-sha2-nistp256) [A-Za-z0-9+/=]+", var.ssh_public_key))
    error_message = "ssh_public_key must be an OpenSSH public key line."
  }
}

variable "vm_size" {
  description = "Size of the virtual machine. Pick the smallest size your subscription has quota for in the region, for example Standard_B2ats_v2 (trial subscriptions often have no B v2 quota: use Standard_D2s_v3)."
  type        = string
  default     = "Standard_B2ats_v2"

  validation {
    condition     = can(regex("^Standard_[A-Za-z0-9_-]+$", var.vm_size))
    error_message = "vm_size must be an Azure size name such as Standard_B2ats_v2."
  }
}

variable "aks_node_size" {
  description = "Size of the single Kubernetes node. AKS needs at least 2 vCPUs and 4 GB of memory, for example Standard_D2as_v4."
  type        = string
  default     = "Standard_D2as_v4"

  validation {
    condition     = can(regex("^Standard_[A-Za-z0-9_-]+$", var.aks_node_size))
    error_message = "aks_node_size must be an Azure size name such as Standard_D2as_v4."
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
