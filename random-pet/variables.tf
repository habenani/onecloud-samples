variable "prefix" {
  description = "Prefix for the generated name"
  type        = string
  default     = "onecloud"
}

variable "name_length" {
  description = "Number of words in the generated name"
  type        = number
  default     = 2
}

variable "environment" {
  description = "Target environment"
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "environment must be dev, test or prod"
  }
}

variable "enable_marker" {
  description = "Write a marker file"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags applied by OneCloudify"
  type        = map(string)
  default     = {}
}

variable "admin_token" {
  description = "A sensitive value, becomes a masked variable"
  type        = string
  sensitive   = true
  default     = ""
}
