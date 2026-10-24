# AWS three tier sample for OneCloudify.
# Its own VPC with a public (web) and a private (app) subnet, an internet gateway for the web subnet only (no NAT
# gateway, so nothing is billed by the hour for the network), security groups per tier, a web and an app server
# (Amazon Linux 2023), EBS data volumes on the app server and a private S3 bucket for app data. Remove deletes all of
# it, the bucket with its objects included.
#
# Day-2 through OneCloudify: variables named <tier>_<setting> belong to aws_instance.web or aws_instance.app, so an
# operation run on one server changes only that server (Resize, Expand disk). Add a data disk grows
# app_data_disk_sizes_gb, Open a port and Close a port change ingress_ports of the web tier, Start, Stop and Restart
# go through the AWS CLI.

locals {
  tags = merge(
    {
      Name        = var.name
      template    = "aws-three-tier"
      template_v  = "2"
      cost_centre = var.cost_centre
    },
    var.test_tag == "" ? {} : { OneCloudTest = var.test_tag },
    var.tags,
  )
  # device names for the data volumes, in the order of app_data_disk_sizes_gb
  data_devices = ["/dev/sdf", "/dev/sdg", "/dev/sdh", "/dev/sdi"]
}

data "aws_availability_zones" "available" {
  state = "available"
}

# Amazon Linux 2023 from Amazon's own images (DescribeImages, no SSM parameter needed)
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ------------------------------------------------------------------ network

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = merge(local.tags, { Name = "${var.name}-vpc" })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = merge(local.tags, { Name = "${var.name}-igw" })
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = false
  tags                    = merge(local.tags, { Name = "${var.name}-public", tier = "web" })
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = data.aws_availability_zones.available.names[0]
  tags              = merge(local.tags, { Name = "${var.name}-private", tier = "app" })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags   = merge(local.tags, { Name = "${var.name}-public" })

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# the private subnet keeps the VPC main route table: local traffic only, no way out to the internet

# ------------------------------------------------------------------ security groups

resource "aws_security_group" "web" {
  name        = "${var.name}-web"
  description = "Web tier of ${var.name}"
  vpc_id      = aws_vpc.this.id
  tags        = merge(local.tags, { Name = "${var.name}-web", tier = "web" })
}

resource "aws_vpc_security_group_ingress_rule" "web" {
  for_each          = toset([for p in var.ingress_ports : tostring(p)])
  security_group_id = aws_security_group.web.id
  description       = "Port ${each.value} from ${var.ingress_source_cidr}"
  ip_protocol       = "tcp"
  from_port         = tonumber(each.value)
  to_port           = tonumber(each.value)
  cidr_ipv4         = var.ingress_source_cidr
  tags              = local.tags
}

resource "aws_vpc_security_group_egress_rule" "web" {
  security_group_id = aws_security_group.web.id
  description       = "All outbound"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  tags              = local.tags
}

resource "aws_security_group" "app" {
  name        = "${var.name}-app"
  description = "App tier of ${var.name}"
  vpc_id      = aws_vpc.this.id
  tags        = merge(local.tags, { Name = "${var.name}-app", tier = "app" })
}

resource "aws_vpc_security_group_ingress_rule" "app" {
  security_group_id            = aws_security_group.app.id
  description                  = "App port from the web tier"
  ip_protocol                  = "tcp"
  from_port                    = var.app_port
  to_port                      = var.app_port
  referenced_security_group_id = aws_security_group.web.id
  tags                         = local.tags
}

resource "aws_vpc_security_group_egress_rule" "app" {
  security_group_id = aws_security_group.app.id
  description       = "Inside the VPC only"
  ip_protocol       = "-1"
  cidr_ipv4         = var.vpc_cidr
  tags              = local.tags
}

# ------------------------------------------------------------------ servers

resource "aws_key_pair" "this" {
  count      = var.ssh_public_key == "" ? 0 : 1
  key_name   = "${var.name}-key"
  public_key = var.ssh_public_key
  tags       = local.tags
}

resource "aws_instance" "web" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.web_instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.web.id]
  associate_public_ip_address = true
  key_name                    = var.ssh_public_key == "" ? null : aws_key_pair.this[0].key_name

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    volume_size           = var.web_root_volume_size
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
    tags                  = merge(local.tags, { Name = "${var.name}-web-root" })
  }

  tags = merge(local.tags, { Name = "${var.name}-web", tier = "web" })
}

resource "aws_instance" "app" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.app_instance_type
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.app.id]
  key_name               = var.ssh_public_key == "" ? null : aws_key_pair.this[0].key_name

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    volume_size           = var.app_root_volume_size
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
    tags                  = merge(local.tags, { Name = "${var.name}-app-root" })
  }

  tags = merge(local.tags, { Name = "${var.name}-app", tier = "app" })
}

resource "aws_ebs_volume" "app_data" {
  count             = length(var.app_data_disk_sizes_gb)
  availability_zone = aws_subnet.private.availability_zone
  size              = var.app_data_disk_sizes_gb[count.index]
  type              = "gp3"
  encrypted         = true
  tags              = merge(local.tags, { Name = "${var.name}-app-data-${count.index}", tier = "app" })
}

resource "aws_volume_attachment" "app_data" {
  count       = length(var.app_data_disk_sizes_gb)
  device_name = local.data_devices[count.index]
  volume_id   = aws_ebs_volume.app_data[count.index].id
  instance_id = aws_instance.app.id
}

# ------------------------------------------------------------------ storage

resource "aws_s3_bucket" "data" {
  bucket_prefix = "${var.name}-data-"
  force_destroy = true
  tags          = merge(local.tags, { Name = "${var.name}-data" })
}

resource "aws_s3_bucket_public_access_block" "data" {
  bucket                  = aws_s3_bucket.data.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "data" {
  bucket = aws_s3_bucket.data.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}
