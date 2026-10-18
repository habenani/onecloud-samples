variable "region" {
  description = "AWS region code. OneCloud fills it from the region picked on the order."
  type        = string
  default     = "us-east-1"
}

variable "name" {
  description = "Name of the instance, shown as its Name tag in AWS. Letters, digits and hyphens, 2 to 40 characters."
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9-]{2,40}$", var.name))
    error_message = "Use 2 to 40 letters, digits or hyphens."
  }
}

variable "test_tag" {
  description = "Value of the OneCloudTest tag, used to find everything this order created, for example a3-1a2b3c."
  type        = string
  default     = "onecloud-sample"
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t3.micro"

  validation {
    condition     = contains(["t3.micro", "t3.small"], var.instance_type)
    error_message = "Pick t3.micro or t3.small."
  }
}

variable "tags" {
  description = "Tags applied to the instance and its disk. OneCloud passes the deployment tags here, including the onecloud_deployment correlation tag."
  type        = map(string)
  default     = {}
}
