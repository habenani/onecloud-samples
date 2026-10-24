variable "region" {
  description = "OCI region identifier, for example uk-london-1. OneCloudify fills it from the region picked on the order."
  type        = string
  default     = "uk-london-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.region))
    error_message = "region must be an OCI region identifier such as uk-london-1."
  }
}

variable "compartment_ocid" {
  description = "Compartment the resources are created in. OneCloudify sets it from the cloud account (TF_VAR_compartment_ocid), so hide it in the variable mapping."
  type        = string
  default     = ""

  validation {
    condition     = var.compartment_ocid == "" || can(regex("^ocid1\\.(compartment|tenancy)\\.oc[0-9]+\\.\\.[a-z0-9]+$", var.compartment_ocid))
    error_message = "compartment_ocid must be a compartment OCID (ocid1.compartment.oc1..) or the tenancy OCID."
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

variable "vcn_cidr" {
  description = "Address range of the VCN in CIDR notation."
  type        = string
  default     = "10.70.0.0/16"

  validation {
    condition     = can(cidrhost(var.vcn_cidr, 0))
    error_message = "vcn_cidr must be a valid CIDR block."
  }
}

variable "public_subnet_cidr" {
  description = "Address range of the public (web) subnet."
  type        = string
  default     = "10.70.1.0/24"

  validation {
    condition     = can(cidrhost(var.public_subnet_cidr, 0))
    error_message = "public_subnet_cidr must be a valid CIDR block."
  }
}

variable "private_subnet_cidr" {
  description = "Address range of the private (app) subnet."
  type        = string
  default     = "10.70.2.0/24"

  validation {
    condition     = can(cidrhost(var.private_subnet_cidr, 0))
    error_message = "private_subnet_cidr must be a valid CIDR block."
  }
}

variable "ingress_ports" {
  description = "TCP ports the web tier accepts from ingress_source_cidr. Each port is its own security rule."
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
  description = "TCP port of the app tier, reachable from the web tier only."
  type        = number
  default     = 8080

  validation {
    condition     = var.app_port >= 1 && var.app_port <= 65535
    error_message = "app_port must be from 1 to 65535."
  }
}

variable "web_shape" {
  description = "Shape of the web server as shape:OCPUs:memory GB. VM.Standard.A1.Flex:1:6 is an Always Free Arm shape (up to 4 OCPUs and 24 GB in total per tenancy, home region only)."
  type        = string
  default     = "VM.Standard.E4.Flex:1:8"

  validation {
    condition     = contains(["VM.Standard.E4.Flex:1:8", "VM.Standard.E4.Flex:2:16", "VM.Standard.E5.Flex:1:8", "VM.Standard.E5.Flex:2:16", "VM.Standard.A1.Flex:1:6"], var.web_shape)
    error_message = "web_shape must be VM.Standard.E4.Flex:1:8, VM.Standard.E4.Flex:2:16, VM.Standard.E5.Flex:1:8, VM.Standard.E5.Flex:2:16 or VM.Standard.A1.Flex:1:6."
  }
}

variable "app_shape" {
  description = "Shape of the app server as shape:OCPUs:memory GB. VM.Standard.A1.Flex:1:6 is an Always Free Arm shape."
  type        = string
  default     = "VM.Standard.E4.Flex:1:8"

  validation {
    condition     = contains(["VM.Standard.E4.Flex:1:8", "VM.Standard.E4.Flex:2:16", "VM.Standard.E5.Flex:1:8", "VM.Standard.E5.Flex:2:16", "VM.Standard.A1.Flex:1:6"], var.app_shape)
    error_message = "app_shape must be VM.Standard.E4.Flex:1:8, VM.Standard.E4.Flex:2:16, VM.Standard.E5.Flex:1:8, VM.Standard.E5.Flex:2:16 or VM.Standard.A1.Flex:1:6."
  }
}

variable "web_boot_volume_size_in_gbs" {
  description = "Boot volume size of the web server in GB. It can grow, never shrink. OCI's smallest boot volume is 50 GB."
  type        = number
  default     = 50

  validation {
    condition     = var.web_boot_volume_size_in_gbs >= 50 && var.web_boot_volume_size_in_gbs <= 200
    error_message = "web_boot_volume_size_in_gbs must be from 50 to 200."
  }
}

variable "app_boot_volume_size_in_gbs" {
  description = "Boot volume size of the app server in GB. It can grow, never shrink."
  type        = number
  default     = 50

  validation {
    condition     = var.app_boot_volume_size_in_gbs >= 50 && var.app_boot_volume_size_in_gbs <= 200
    error_message = "app_boot_volume_size_in_gbs must be from 50 to 200."
  }
}

variable "app_data_disk_sizes_gb" {
  description = "Sizes in GB of the block volumes on the app server, one entry per volume. Add to the end of the list only. OCI's smallest block volume is 50 GB."
  type        = list(number)
  default     = [50]

  validation {
    condition     = alltrue([for s in var.app_data_disk_sizes_gb : s >= 50 && s <= 200]) && length(var.app_data_disk_sizes_gb) <= 4
    error_message = "app_data_disk_sizes_gb must hold up to 4 sizes from 50 to 200."
  }
}

variable "ssh_public_key" {
  description = "Optional OpenSSH public key for the opc user on both servers. Leave empty to use the OCI Bastion service or the serial console instead."
  type        = string
  default     = ""

  validation {
    condition     = var.ssh_public_key == "" || can(regex("^(ssh-ed25519|ssh-rsa|ecdsa-sha2-nistp256) [A-Za-z0-9+/=]+", var.ssh_public_key))
    error_message = "ssh_public_key must be empty or an OpenSSH public key line."
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
  description = "Tags applied to every resource as free form tags. OneCloudify passes the deployment tags here, including the onecloud_deployment correlation tag."
  type        = map(string)
  default     = {}
}
