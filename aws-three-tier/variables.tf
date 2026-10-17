variable "region" {
  description = "AWS region code, for example eu-west-2. OneCloud fills it from the region picked on the order."
  type        = string
  default     = "eu-west-2"
}

variable "name" {
  description = "Base name for the deployment. Lowercase letters, digits and hyphens, 2 to 24 characters."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,23}$", var.name))
    error_message = "name must be 2 to 24 characters of lowercase letters, digits and hyphens, starting with a letter or digit."
  }
}

variable "vpc_cidr" {
  description = "Address range of the VPC in CIDR notation."
  type        = string
  default     = "10.80.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid CIDR block."
  }
}

variable "public_subnet_cidr" {
  description = "Address range of the public (web) subnet."
  type        = string
  default     = "10.80.1.0/24"

  validation {
    condition     = can(cidrhost(var.public_subnet_cidr, 0))
    error_message = "public_subnet_cidr must be a valid CIDR block."
  }
}

variable "private_subnet_cidr" {
  description = "Address range of the private (app) subnet."
  type        = string
  default     = "10.80.2.0/24"

  validation {
    condition     = can(cidrhost(var.private_subnet_cidr, 0))
    error_message = "private_subnet_cidr must be a valid CIDR block."
  }
}

variable "ingress_ports" {
  description = "TCP ports the web tier accepts from ingress_source_cidr."
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
  description = "TCP port of the app tier, reachable from the web subnet only."
  type        = number
  default     = 8080

  validation {
    condition     = var.app_port >= 1 && var.app_port <= 65535
    error_message = "app_port must be from 1 to 65535."
  }
}

variable "web_instance_type" {
  description = "EC2 instance type of the web server."
  type        = string
  default     = "t3.micro"

  validation {
    condition     = contains(["t3.micro", "t3.small"], var.web_instance_type)
    error_message = "web_instance_type must be t3.micro or t3.small."
  }
}

variable "app_instance_type" {
  description = "EC2 instance type of the app server."
  type        = string
  default     = "t3.micro"

  validation {
    condition     = contains(["t3.micro", "t3.small"], var.app_instance_type)
    error_message = "app_instance_type must be t3.micro or t3.small."
  }
}

variable "web_root_volume_size" {
  description = "Root disk size of the web server in GB. It can grow, never shrink."
  type        = number
  default     = 8

  validation {
    condition     = var.web_root_volume_size >= 8 && var.web_root_volume_size <= 100
    error_message = "web_root_volume_size must be from 8 to 100."
  }
}

variable "app_root_volume_size" {
  description = "Root disk size of the app server in GB. It can grow, never shrink."
  type        = number
  default     = 8

  validation {
    condition     = var.app_root_volume_size >= 8 && var.app_root_volume_size <= 100
    error_message = "app_root_volume_size must be from 8 to 100."
  }
}

variable "app_data_disk_sizes_gb" {
  description = "Sizes in GB of the EBS data volumes on the app server, one entry per volume. Add to the end of the list only."
  type        = list(number)
  default     = [8]

  validation {
    condition     = alltrue([for s in var.app_data_disk_sizes_gb : s >= 1 && s <= 100]) && length(var.app_data_disk_sizes_gb) <= 4
    error_message = "app_data_disk_sizes_gb must hold up to 4 sizes from 1 to 100."
  }
}

variable "ssh_public_key" {
  description = "Optional OpenSSH public key for ec2-user on both servers. Leave empty for no key pair (use Session Manager instead)."
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
  description = "Tags applied to every resource. OneCloud passes the deployment tags here, including the onecloud_deployment correlation tag."
  type        = map(string)
  default     = {}
}
