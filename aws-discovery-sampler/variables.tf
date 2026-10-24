variable "region" {
  description = "AWS region code, for example eu-north-1. OneCloudify fills it from the region picked on the order."
  type        = string
  default     = "eu-north-1"
}

variable "name" {
  description = "Base name for every resource. Lowercase letters, digits and hyphens, 2 to 20 characters."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,19}$", var.name))
    error_message = "name must be 2 to 20 characters of lowercase letters, digits and hyphens, starting with a letter."
  }
}

variable "instance_type" {
  description = "EC2 instance type, the smallest your account allows, for example t3.micro."
  type        = string
  default     = "t3.micro"
}

variable "db_instance_class" {
  description = "RDS instance class, for example db.t3.micro or db.t4g.micro."
  type        = string
  default     = "db.t3.micro"
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
  description = "Tags applied to every resource. OneCloudify passes the deployment tags here, including the onecloud_deployment correlation tag."
  type        = map(string)
  default     = {}
}
