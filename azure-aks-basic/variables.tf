variable "name" {
  description = "Name of the cluster, also its DNS prefix. Lowercase letters, digits and hyphens, 3 to 40 characters."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,38}[a-z0-9]$", var.name))
    error_message = "name must be 3 to 40 characters of lowercase letters, digits and hyphens, starting with a letter and not ending with a hyphen."
  }
}

variable "resource_group_name" {
  description = "Resource group the template creates for the cluster. Remove deletes it. Azure keeps the nodes in a second group, MC_<group>_<cluster>_<region>, and deletes that one with the cluster."
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9._()-]{1,80}$", var.resource_group_name))
    error_message = "resource_group_name must be 1 to 80 characters of letters, digits, periods, underscores, hyphens or parentheses."
  }
}

variable "location" {
  description = "Azure region code, for example uksouth. OneCloudify fills it from the account region when the variable mapping says so."
  type        = string
  default     = "uksouth"
}

variable "kubernetes_version" {
  description = "Kubernetes minor version of the control plane and the system node pool. Azure picks the latest patch. Upgrade one minor version at a time."
  type        = string
  default     = "1.35"

  validation {
    condition     = contains(["1.35", "1.36", "1.37"], var.kubernetes_version)
    error_message = "kubernetes_version must be 1.35, 1.36 or 1.37 (the versions AKS supports in UK South on 17 October 2026, az aks get-versions)."
  }
}

variable "node_count" {
  description = "Number of nodes in the system node pool. Each node is one virtual machine of node_vm_size and counts against the regional vCPU quota."
  type        = number
  default     = 1

  validation {
    condition     = var.node_count >= 1 && var.node_count <= 3
    error_message = "node_count must be from 1 to 3."
  }
}

variable "node_vm_size" {
  description = "Size of each node. Both sizes have 2 vCPUs and 8 GB of memory."
  type        = string
  default     = "Standard_D2as_v4"

  validation {
    condition     = contains(["Standard_D2as_v4", "Standard_D2s_v3"], var.node_vm_size)
    error_message = "node_vm_size must be Standard_D2as_v4 or Standard_D2s_v3."
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

variable "cost_centre" {
  description = "Cost centre the cluster is charged to, put on every resource as the cost_centre tag."
  type        = string
  default     = "CC-1001"

  validation {
    condition     = can(regex("^[A-Za-z0-9-]{1,20}$", var.cost_centre))
    error_message = "cost_centre must be 1 to 20 letters, digits or hyphens."
  }
}

variable "tags" {
  description = "Tags applied to every resource. OneCloudify passes the deployment tags here, including the onecloud_deployment correlation tag."
  type        = map(string)
  default     = {}
}
