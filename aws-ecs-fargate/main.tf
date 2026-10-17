# Amazon ECS on Fargate sample for OneCloud.
# One ECS cluster, one task definition with a single container from a public image, a security group and a Fargate
# service in the default VPC with public IP addresses. The key that runs it needs ECS rights and EC2 security group
# rights (create, authorize, revoke, delete).
#
# Day-2 through OneCloud: Scale service sets desired_count; Update changes image, task_cpu or task_memory (a new task
# definition revision, the service rolls to it).

locals {
  tags = merge(
    {
      Name        = var.name
      template    = "aws-ecs-fargate"
      cost_centre = var.cost_centre
    },
    var.test_tag == "" ? {} : { OneCloudTest = var.test_tag },
    var.tags,
  )
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

resource "aws_ecs_cluster" "this" {
  name = var.name
  tags = local.tags
}

resource "aws_ecs_task_definition" "this" {
  family                   = var.name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  tags                     = local.tags

  container_definitions = jsonencode([
    {
      name         = "app"
      image        = var.image
      essential    = true
      portMappings = [{ containerPort = var.port, protocol = "tcp" }]
    }
  ])
}

resource "aws_security_group" "service" {
  name        = "${var.name}-service"
  description = "Traffic to the ${var.name} tasks"
  vpc_id      = data.aws_vpc.default.id
  tags        = local.tags

  ingress {
    description = "Container port"
    from_port   = var.port
    to_port     = var.port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Image pulls and outbound calls"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecs_service" "this" {
  name            = var.name
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"
  tags            = local.tags

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = [aws_security_group.service.id]
    assign_public_ip = true
  }
}
