variable "region" {
  description = "OCI region identifier, for example uk-london-1. OneCloud fills it from the region picked on the order."
  type        = string
  default     = "uk-london-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.region))
    error_message = "region must be an OCI region identifier such as uk-london-1."
  }
}

variable "compartment_ocid" {
  description = "Compartment the resources are created in. OneCloud sets it from the cloud account (TF_VAR_compartment_ocid), so hide it in the variable mapping."
  type        = string
  default     = ""

  validation {
    condition     = var.compartment_ocid == "" || can(regex("^ocid1\\.(compartment|tenancy)\\.oc[0-9]+\\.\\.[a-z0-9]+$", var.compartment_ocid))
    error_message = "compartment_ocid must be a compartment OCID (ocid1.compartment.oc1..) or the tenancy OCID."
  }
}

variable "name" {
  description = "Name of the cluster. Lowercase letters, digits and hyphens, 3 to 30 characters, starting with a letter."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,28}[a-z0-9]$", var.name))
    error_message = "name must be 3 to 30 characters of lowercase letters, digits and hyphens, starting with a letter and not ending with a hyphen."
  }
}

variable "kubernetes_version" {
  description = "Kubernetes minor version of the control plane and the node pool. OneCloud picks the newest patch OKE offers for it. Upgrade one minor version at a time: the control plane first, then the node pool."
  type        = string
  default     = "1.33"

  validation {
    condition     = contains(["1.33", "1.34", "1.35"], var.kubernetes_version)
    error_message = "kubernetes_version must be 1.33, 1.34 or 1.35. Check the versions OKE offers in your region (oci ce cluster-options get --cluster-option-id all) and change the list to match."
  }
}

variable "node_count" {
  description = "Number of worker nodes in the node pool."
  type        = number
  default     = 1

  validation {
    condition     = var.node_count >= 1 && var.node_count <= 3
    error_message = "node_count must be from 1 to 3."
  }
}

variable "node_shape" {
  description = "Shape of each worker node as shape:OCPUs:memory GB."
  type        = string
  default     = "VM.Standard.E4.Flex:1:8"

  validation {
    condition     = contains(["VM.Standard.E4.Flex:1:8", "VM.Standard.E4.Flex:2:16", "VM.Standard.E5.Flex:1:8", "VM.Standard.E5.Flex:2:16"], var.node_shape)
    error_message = "node_shape must be VM.Standard.E4.Flex:1:8, VM.Standard.E4.Flex:2:16, VM.Standard.E5.Flex:1:8 or VM.Standard.E5.Flex:2:16."
  }
}

variable "vcn_cidr" {
  description = "Address range of the cluster VCN. The endpoint subnet takes the first /28, the node subnet the second /24."
  type        = string
  default     = "10.60.0.0/16"

  validation {
    condition     = can(cidrsubnet(var.vcn_cidr, 8, 2))
    error_message = "vcn_cidr must be a valid CIDR block of /22 or larger."
  }
}

variable "api_source_cidr" {
  description = "Who may reach the Kubernetes API endpoint, a CIDR block. 0.0.0.0/0 means anywhere."
  type        = string
  default     = "0.0.0.0/0"

  validation {
    condition     = can(cidrhost(var.api_source_cidr, 0))
    error_message = "api_source_cidr must be a valid CIDR block."
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
  description = "Cost centre the resources are charged to, put on every resource as the cost_centre tag."
  type        = string
  default     = "CC-1001"

  validation {
    condition     = can(regex("^[A-Za-z0-9-]{1,20}$", var.cost_centre))
    error_message = "cost_centre must be 1 to 20 letters, digits or hyphens."
  }
}

variable "tags" {
  description = "Tags applied to every resource as free form tags. OneCloud passes the deployment tags here, including the onecloud_deployment correlation tag."
  type        = map(string)
  default     = {}
}
