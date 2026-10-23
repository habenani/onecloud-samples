// Network inputs and resources.

variable "vpc" {
  description = "VPC settings: CIDR block, DNS and an optional flow log block"
  type = object({
    cidr            = string               # main CIDR block
    enable_dns      = optional(bool, true) // DNS host names
    secondary_cidrs = optional(list(string), []) /* extra blocks */
    flow_log = optional(object({
      enabled   = bool
      retention = optional(number, 7)
    }))
  })
  default = {
    cidr = "10.42.0.0/16"
  }

  validation {
    condition     = can(cidrhost(var.vpc.cidr, 0))
    error_message = "vpc.cidr must be a valid CIDR block."
  }
}

variable "subnets" {
  description = "Subnets by name"
  type = map(object({
    cidr     = string
    az_index = number
    public   = optional(bool, false)
    tags     = optional(map(string), {})
  }))
  default = {
    "app-a" = { cidr = "10.42.1.0/24", az_index = 0 }
    "app-b" = { cidr = "10.42.2.0/24", az_index = 1, tags = { tier = "app" } }
    web = {
      cidr     = "10.42.10.0/24"
      az_index = 0
      public   = true
    }
  }
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["eu-north-1a", "eu-north-1b"]

  validation {
    condition     = length(var.availability_zones) >= 1 && length(var.availability_zones) <= 3
    error_message = "Give one to three availability zones."
  }
}

variable "max_az_count" {
  description = "Most availability zones to use"
  type        = number
  default     = 2

  validation {
    condition     = var.max_az_count >= 1 && var.max_az_count <= 3
    error_message = "Use 1, 2 or 3."
  }
}

variable "network_acl_rules" {
  description = "Extra inbound network ACL rules"
  type = list(object({
    rule_no = number
    action  = string
    cidr    = string
    from    = number
    to      = number
  }))
  default = [
    { rule_no = 100, action = "allow", cidr = "10.0.0.0/8", from = 443, to = 443 },
  ]
}

variable "dns_servers" {
  description = "Custom DNS servers. Leave empty for the AWS resolver."
  type        = list(string)
  default     = null
}

variable "region_pair" {
  description = "Primary and fallback region"
  type        = tuple([string, string])
  default     = ["eu-north-1", "eu-west-1"]
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc.cidr
  enable_dns_hostnames = var.vpc.enable_dns
  enable_dns_support   = true
  tags                 = merge(local.tags, { Name = "${var.name}-vpc" })
}

module "subnets" {
  source = "./modules/subnet-set"

  vpc_id             = aws_vpc.main.id
  subnets            = var.subnets
  availability_zones = slice(var.availability_zones, 0, min(var.max_az_count, length(var.availability_zones)))
  name_prefix        = var.name
  tags               = local.tags
}

resource "aws_network_acl" "main" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = values(module.subnets.ids)
  tags       = merge(local.tags, { Name = "${var.name}-nacl" })

  dynamic "ingress" {
    for_each = var.network_acl_rules
    content {
      rule_no    = ingress.value.rule_no
      action     = ingress.value.action
      protocol   = "tcp"
      cidr_block = ingress.value.cidr
      from_port  = ingress.value.from
      to_port    = ingress.value.to
    }
  }

  egress {
    rule_no    = 100
    action     = "allow"
    protocol   = "-1"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
}
