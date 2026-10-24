variable "name" {
  description = "Name of the container group, also the start of its public DNS name. Lowercase letters, digits and hyphens, 3 to 40 characters."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,38}[a-z0-9]$", var.name))
    error_message = "name must be 3 to 40 characters of lowercase letters, digits and hyphens, starting with a letter and not ending with a hyphen."
  }
}

variable "resource_group_name" {
  description = "Resource group the template creates for the container group. Remove deletes it."
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9._()-]{1,90}$", var.resource_group_name))
    error_message = "resource_group_name must be 1 to 90 characters of letters, digits, periods, underscores, hyphens or parentheses."
  }
}

variable "location" {
  description = "Azure region code, for example uksouth. OneCloudify fills it from the account region when the variable mapping says so."
  type        = string
  default     = "uksouth"
}

variable "image" {
  description = "Container image to run, from a public registry. The default is the Azure hello world web page on port 80."
  type        = string
  default     = "mcr.microsoft.com/azuredocs/aci-helloworld:latest"

  validation {
    condition     = can(regex("^[a-z0-9.-]+(:[0-9]+)?/[a-z0-9._/-]+(:[A-Za-z0-9._-]{1,128})?$", var.image))
    error_message = "image must be a registry/repository reference such as mcr.microsoft.com/azuredocs/aci-helloworld:latest."
  }
}

variable "cpu_cores" {
  description = "CPU cores for the container. Changing it recreates the container group, so it is briefly unavailable."
  type        = number
  default     = 1

  validation {
    condition     = contains([0.5, 1, 2], var.cpu_cores)
    error_message = "cpu_cores must be 0.5, 1 or 2."
  }
}

variable "memory_gb" {
  description = "Memory for the container in GB. Changing it recreates the container group."
  type        = number
  default     = 1.5

  validation {
    condition     = contains([0.5, 1, 1.5, 2, 4], var.memory_gb)
    error_message = "memory_gb must be 0.5, 1, 1.5, 2 or 4."
  }
}

variable "port" {
  description = "TCP port the container listens on, opened on the public IP address."
  type        = number
  default     = 80

  validation {
    condition     = var.port >= 1 && var.port <= 65535
    error_message = "port must be from 1 to 65535."
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
  description = "Cost centre the container group is charged to, put on every resource as the cost_centre tag."
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
