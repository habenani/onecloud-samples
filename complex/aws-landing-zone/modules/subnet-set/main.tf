# Local module: one subnet per entry of var.subnets. Its variables are not template inputs.
variable "vpc_id" { type = string }
variable "subnets" {
  type = map(object({
    cidr     = string
    az_index = number
    public   = optional(bool, false)
    tags     = optional(map(string), {})
  }))
}
variable "availability_zones" { type = list(string) }
variable "name_prefix" { type = string }
variable "tags" { type = map(string) }

resource "aws_subnet" "this" {
  for_each                = var.subnets
  vpc_id                  = var.vpc_id
  cidr_block              = each.value.cidr
  availability_zone       = var.availability_zones[each.value.az_index % length(var.availability_zones)]
  map_public_ip_on_launch = each.value.public
  tags                    = merge(var.tags, each.value.tags, { Name = "${var.name_prefix}-${each.key}" })
}

output "ids" {
  value = { for k, s in aws_subnet.this : k => s.id }
}
