# AWS discovery sampler for OneCloudify.
# One small deployment that holds one of each AWS resource type OneCloudify records in the CMDB, so an admin can check in
# one run how each type lands: written from the Terraform state, confirmed by targeted pattern discovery where the
# resource type map names a pattern, or recorded in the generic Cloud Resource class when the type has no mapping.
# Everything is private (no internet gateway, internal load balancer, database not publicly accessible). Order it,
# read the CMDB and Discovery steps of the run, then Remove it. The database and the load balancer cost the most per
# hour, so do not keep the deployment longer than the check needs.

locals {
  tags = merge(
    {
      Name     = var.name
      template = "aws-discovery-sampler"
    },
    var.test_tag == "" ? {} : { OneCloudTest = var.test_tag },
    var.tags,
  )
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
}

resource "random_password" "db" {
  length           = 24
  special          = true
  override_special = "-_.!"
}

# ------------------------------------------------------------------ network
resource "aws_vpc" "this" {
  cidr_block           = "10.90.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = merge(local.tags, { Name = "${var.name}-vpc" })
}

# two subnets in two zones: the load balancer and the database subnet group need two
resource "aws_subnet" "a" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = "10.90.1.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
  tags              = merge(local.tags, { Name = "${var.name}-subnet-a" })
}

resource "aws_subnet" "b" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = "10.90.2.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]
  tags              = merge(local.tags, { Name = "${var.name}-subnet-b" })
}

resource "aws_security_group" "this" {
  name        = "${var.name}-sg"
  description = "Discovery sampler: HTTP and PostgreSQL inside the VPC"
  vpc_id      = aws_vpc.this.id
  tags        = merge(local.tags, { Name = "${var.name}-sg" })

  ingress {
    description = "HTTP inside the VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.this.cidr_block]
  }

  ingress {
    description = "PostgreSQL inside the VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.this.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ------------------------------------------------------------------ compute and storage
resource "aws_instance" "this" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.a.id
  vpc_security_group_ids = [aws_security_group.this.id]
  tags                   = merge(local.tags, { Name = "${var.name}-vm" })

  # tags on the root volume only: volume_tags would also rename the data volume attached later
  root_block_device {
    volume_size = 8
    volume_type = "gp3"
    tags        = merge(local.tags, { Name = "${var.name}-root" })
  }
}

resource "aws_ebs_volume" "data" {
  availability_zone = aws_subnet.a.availability_zone
  size              = 1
  type              = "gp3"
  tags              = merge(local.tags, { Name = "${var.name}-data" })
}

resource "aws_volume_attachment" "data" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.data.id
  instance_id = aws_instance.this.id
}

# A type with no resource type mapping: OneCloudify records it in the generic Cloud Resource class.
resource "aws_cloudwatch_log_group" "this" {
  name              = "/onecloudify/${var.name}"
  retention_in_days = 1
  tags              = local.tags
}

# ------------------------------------------------------------------ load balancer (internal application load balancer)
resource "aws_lb" "this" {
  name               = "${var.name}-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.this.id]
  subnets            = [aws_subnet.a.id, aws_subnet.b.id]
  tags               = local.tags
}

# ------------------------------------------------------------------ database (RDS PostgreSQL, smallest class)
resource "aws_db_subnet_group" "this" {
  name       = "${var.name}-db"
  subnet_ids = [aws_subnet.a.id, aws_subnet.b.id]
  tags       = local.tags
}

resource "aws_db_instance" "this" {
  identifier              = "${var.name}-db"
  engine                  = "postgres"
  instance_class          = var.db_instance_class
  allocated_storage       = 20
  storage_type            = "gp2"
  username                = "sampleradmin"
  password                = random_password.db.result
  db_subnet_group_name    = aws_db_subnet_group.this.name
  vpc_security_group_ids  = [aws_security_group.this.id]
  publicly_accessible     = false
  multi_az                = false
  skip_final_snapshot     = true
  deletion_protection     = false
  backup_retention_period = 0
  tags                    = local.tags
}
