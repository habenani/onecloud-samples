variable "name" {
  description = "Name of the EKS cluster. Letters, digits and hyphens, 3 to 40 characters, starting with a letter."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]{2,39}$", var.name))
    error_message = "name must be 3 to 40 letters, digits or hyphens, starting with a letter."
  }
}

variable "kubernetes_version" {
  description = "Kubernetes minor version of the control plane and the managed node group. Upgrade one minor version at a time."
  type        = string
  default     = "1.36"

  validation {
    condition     = contains(["1.35", "1.36", "1.37"], var.kubernetes_version)
    error_message = "kubernetes_version must be 1.35, 1.36 or 1.37 (EKS standard support on 17 October 2026)."
  }
}

variable "node_count" {
  description = "Number of nodes in the managed node group."
  type        = number
  default     = 1

  validation {
    condition     = var.node_count >= 1 && var.node_count <= 3
    error_message = "node_count must be from 1 to 3."
  }
}

variable "node_instance_type" {
  description = "EC2 instance type of the nodes. An AWS account on the Free plan launches only free tier eligible types: pick t3.small, c7i-flex.large or m7i-flex.large there."
  type        = string
  default     = "t3.medium"

  validation {
    condition     = contains(["t3.small", "t3.medium", "t3.large", "c7i-flex.large", "m7i-flex.large"], var.node_instance_type)
    error_message = "node_instance_type must be t3.small, t3.medium, t3.large, c7i-flex.large or m7i-flex.large."
  }
}

variable "region" {
  description = "AWS region code. OneCloud fills it from the region picked on the order."
  type        = string
  default     = "us-east-1"
}

variable "test_tag" {
  description = "Value of the OneCloudTest tag put on every resource, so a test can find what it made. Leave empty outside tests."
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
  description = "Tags applied to every resource. OneCloud passes the deployment tags here, including the onecloud_deployment correlation tag."
  type        = map(string)
  default     = {}
}
