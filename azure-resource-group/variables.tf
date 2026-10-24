variable "name" {
  description = "Resource group name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "uksouth"
}

variable "create_storage_account" {
  description = "Also create a storage account"
  type        = bool
  default     = false
}

variable "storage_account_name" {
  description = "Globally unique storage account name (lowercase letters and numbers)"
  type        = string
  default     = ""
}

variable "replication_type" {
  description = "Storage replication"
  type        = string
  default     = "ZRS"
  validation {
    condition     = contains(["LRS", "GRS", "ZRS"], var.replication_type)
    error_message = "replication_type must be LRS, GRS or ZRS"
  }
}

variable "tags" {
  description = "Tags applied by OneCloudify"
  type        = map(string)
  default     = {}
}
