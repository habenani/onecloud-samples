variable "allowed_ports" {
  description = "Ports open to the admin networks"
  type        = list(number)
  default     = [443, 8443]

  validation {
    condition     = alltrue([for p in var.allowed_ports : p >= 1 && p <= 65535])
    error_message = "Ports are numbers from 1 to 65535."
  }
}

variable "admin_cidrs" {
  description = "Admin networks"
  type        = set(string)
  default     = ["10.20.0.0/16"]

  validation {
    condition     = alltrue([for c in var.admin_cidrs : can(cidrhost(c, 0))])
    error_message = "Each admin network must be a CIDR block such as 10.20.0.0/16."
  }
}

variable "ingress_rules" {
  description = "Extra inbound rules for the application security group"
  type = list(object({
    description = string
    port        = number
    protocol    = optional(string, "tcp")
    cidrs       = list(string)
  }))
  default = [
    {
      description = "Health checks"
      port        = 8080
      cidrs       = ["10.42.0.0/16"]
    },
  ]
}

resource "aws_security_group" "app" {
  name        = "${var.name}-app"
  description = "Application tier of ${var.name}"
  vpc_id      = aws_vpc.main.id
  tags        = local.tags

  dynamic "ingress" {
    for_each = var.allowed_ports
    content {
      description = "Admin port ${ingress.value}"
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = sort(tolist(var.admin_cidrs))
    }
  }

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      description = ingress.value.description
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidrs
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
