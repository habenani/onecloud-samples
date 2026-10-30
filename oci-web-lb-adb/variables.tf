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
  description = "Base name for the deployment. Lowercase letters, digits and hyphens, 2 to 20 characters, starting with a letter."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,19}$", var.name))
    error_message = "name must be 2 to 20 characters of lowercase letters, digits and hyphens, starting with a letter."
  }
}

variable "vcn_cidr" {
  description = "Address range of the VCN in CIDR notation."
  type        = string
  default     = "10.71.0.0/16"

  validation {
    condition     = can(cidrhost(var.vcn_cidr, 0))
    error_message = "vcn_cidr must be a valid CIDR block."
  }
}

variable "public_subnet_cidr" {
  description = "Address range of the public subnet (load balancer)."
  type        = string
  default     = "10.71.1.0/24"

  validation {
    condition     = can(cidrhost(var.public_subnet_cidr, 0))
    error_message = "public_subnet_cidr must be a valid CIDR block."
  }
}

variable "private_subnet_cidr" {
  description = "Address range of the private subnet (web servers and database)."
  type        = string
  default     = "10.71.2.0/24"

  validation {
    condition     = can(cidrhost(var.private_subnet_cidr, 0))
    error_message = "private_subnet_cidr must be a valid CIDR block."
  }
}

variable "web_server_count" {
  description = "Number of web servers behind the load balancer."
  type        = number
  default     = 2

  validation {
    condition     = var.web_server_count >= 1 && var.web_server_count <= 4
    error_message = "web_server_count must be from 1 to 4."
  }
}

variable "web_shape" {
  description = "Shape of every web server as shape:OCPUs:memory GB."
  type        = string
  default     = "VM.Standard.E4.Flex:1:8"

  validation {
    condition     = contains(["VM.Standard.E4.Flex:1:8", "VM.Standard.E4.Flex:2:16", "VM.Standard.E5.Flex:1:8", "VM.Standard.E5.Flex:2:16"], var.web_shape)
    error_message = "web_shape must be VM.Standard.E4.Flex:1:8, VM.Standard.E4.Flex:2:16, VM.Standard.E5.Flex:1:8 or VM.Standard.E5.Flex:2:16."
  }
}

variable "web_boot_volume_size_in_gbs" {
  description = "Boot volume size of each web server in GB (50 is the OCI minimum). It can grow, never shrink."
  type        = number
  default     = 50

  validation {
    condition     = var.web_boot_volume_size_in_gbs >= 50 && var.web_boot_volume_size_in_gbs <= 200
    error_message = "web_boot_volume_size_in_gbs must be from 50 to 200."
  }
}

variable "web_port" {
  description = "TCP port the load balancer and the web servers listen on."
  type        = number
  default     = 80

  validation {
    condition     = var.web_port >= 1 && var.web_port <= 65535
    error_message = "web_port must be from 1 to 65535."
  }
}

variable "ingress_source_cidr" {
  description = "Where the load balancer may be reached from, a CIDR block. 0.0.0.0/0 means anywhere."
  type        = string
  default     = "0.0.0.0/0"

  validation {
    condition     = can(cidrhost(var.ingress_source_cidr, 0))
    error_message = "ingress_source_cidr must be a valid CIDR block."
  }
}

variable "lb_bandwidth_mbps" {
  description = "Bandwidth of the flexible load balancer in Mbps (10 is the smallest; the first 10 Mbps load balancer of a tenancy is Always Free)."
  type        = number
  default     = 10

  validation {
    condition     = contains([10, 50, 100, 400], var.lb_bandwidth_mbps)
    error_message = "lb_bandwidth_mbps must be 10, 50, 100 or 400."
  }
}

variable "db_ecpu" {
  description = "ECPUs of the Autonomous Database (2 is the smallest)."
  type        = number
  default     = 2

  validation {
    condition     = contains([2, 4, 8], var.db_ecpu)
    error_message = "db_ecpu must be 2, 4 or 8."
  }
}

variable "db_storage_gb" {
  description = "Database storage in GB (20 is the smallest). It can grow, never shrink."
  type        = number
  default     = 20

  validation {
    condition     = var.db_storage_gb >= 20 && var.db_storage_gb <= 1024
    error_message = "db_storage_gb must be from 20 to 1024."
  }
}

variable "db_license_model" {
  description = "LICENSE_INCLUDED, or BRING_YOUR_OWN_LICENSE when you hold Oracle Database Enterprise Edition licences."
  type        = string
  default     = "LICENSE_INCLUDED"

  validation {
    condition     = contains(["LICENSE_INCLUDED", "BRING_YOUR_OWN_LICENSE"], var.db_license_model)
    error_message = "db_license_model must be LICENSE_INCLUDED or BRING_YOUR_OWN_LICENSE."
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
  description = "Cost centre the resources are charged to, put on every resource as the cost_centre free form tag."
  type        = string
  default     = "CC-1001"

  validation {
    condition     = can(regex("^[A-Za-z0-9-]{1,20}$", var.cost_centre))
    error_message = "cost_centre must be 1 to 20 letters, digits or hyphens."
  }
}

variable "tags" {
  description = "Free form tags applied to every resource. OneCloudify passes the deployment tags here, including the onecloud_deployment correlation tag."
  type        = map(string)
  default     = {}
}
