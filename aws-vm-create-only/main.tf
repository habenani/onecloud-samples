# Amazon Linux 2023 from Amazon's own images. Looked up with DescribeImages rather than the public SSM
# parameter, because the OneCloud test key may not call ssm:GetParameter.
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

locals {
  tags = merge(var.tags, {
    Name         = var.name
    OneCloudTest = var.test_tag
    Owner        = "OneCloud test"
  })
}

# One instance in the default VPC. No subnet and no security group are given, so AWS picks a default
# subnet and attaches the VPC's default security group. Terraform therefore never creates a security
# group, which would need ec2:RevokeSecurityGroupEgress.
resource "aws_instance" "vm" {
  ami           = data.aws_ami.al2023.id
  instance_type = var.instance_type

  root_block_device {
    volume_size           = 8
    volume_type           = "gp3"
    delete_on_termination = true
    tags                  = local.tags
  }

  tags = local.tags
}
