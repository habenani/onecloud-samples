variable "name" {
  description = "Name of the virtual machine. Letters, digits and hyphens, 2 to 63 characters."
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9][A-Za-z0-9-]{1,62}$", var.name))
    error_message = "name must be 2 to 63 characters of letters, digits and hyphens, starting with a letter or digit."
  }
}

variable "datacenter" {
  description = "vCenter datacenter. OneCloudify fills this from the selected account region (the region code is the datacenter name)."
  type        = string
}

variable "resource_pool" {
  description = "Resource pool the virtual machine runs in, as its path in the datacenter: <cluster>/Resources for a cluster's root pool, <cluster>/Resources/<pool> for a pool, <host>/Resources for a standalone host."
  type        = string
}

variable "datastore" {
  description = "Datastore that holds the virtual machine files."
  type        = string
}

variable "network" {
  description = "Port group or network the virtual machine connects to."
  type        = string
  default     = "VM Network"
}

variable "folder" {
  description = "VM folder, relative to the datacenter's vm folder. Empty puts the VM in the root vm folder."
  type        = string
  default     = ""
}

variable "template" {
  description = "VM template to clone. Empty creates an empty virtual machine (lab use, no operating system)."
  type        = string
  default     = ""
}

variable "num_cpus" {
  description = "Virtual CPUs."
  type        = number
  default     = 2

  validation {
    condition     = contains([1, 2, 4, 8], var.num_cpus)
    error_message = "num_cpus must be 1, 2, 4 or 8."
  }
}

variable "memory_mb" {
  description = "Memory in MB."
  type        = number
  default     = 4096

  validation {
    condition     = contains([1024, 2048, 4096, 8192, 16384], var.memory_mb)
    error_message = "memory_mb must be 1024, 2048, 4096, 8192 or 16384."
  }
}

variable "disk_gb" {
  description = "Size of the system disk in GB (at least the template's disk size when cloning)."
  type        = number
  default     = 40

  validation {
    condition     = var.disk_gb >= 1 && var.disk_gb <= 2048
    error_message = "disk_gb must be between 1 and 2048."
  }
}

variable "guest_id" {
  description = "Guest operating system id of an empty virtual machine (ignored when cloning a template)."
  type        = string
  default     = "otherLinux64Guest"
}

variable "tags" {
  description = "OneCloudify tags. vSphere has no free form tags on a VM, so they are written into the VM notes (annotation) as key=value lines, and the onecloud_deployment value also as a custom attribute when one named so exists."
  type        = map(string)
  default     = {}
}
