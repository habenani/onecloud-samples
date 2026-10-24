variable "name" {
  description = "Name of the ECS cluster and service. Letters, digits and hyphens, 3 to 32 characters."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]{2,31}$", var.name))
    error_message = "name must be 3 to 32 letters, digits or hyphens, starting with a letter."
  }
}

variable "image" {
  description = "Container image to run, from a public registry."
  type        = string
  default     = "public.ecr.aws/nginx/nginx:stable"
}

variable "desired_count" {
  description = "Number of tasks the service runs. Zero keeps the service without running anything."
  type        = number
  default     = 1

  validation {
    condition     = var.desired_count >= 0 && var.desired_count <= 10
    error_message = "desired_count must be from 0 to 10."
  }
}

variable "task_cpu" {
  description = "CPU units of each task (256 is a quarter of a vCPU)."
  type        = string
  default     = "256"

  validation {
    condition     = contains(["256", "512", "1024"], var.task_cpu)
    error_message = "task_cpu must be 256, 512 or 1024."
  }
}

variable "task_memory" {
  description = "Memory of each task in MiB. Must suit task_cpu (256 takes 512 to 2048)."
  type        = string
  default     = "512"

  validation {
    condition     = contains(["512", "1024", "2048"], var.task_memory)
    error_message = "task_memory must be 512, 1024 or 2048."
  }
}

variable "port" {
  description = "TCP port the container listens on, open to the internet on each task's public IP address."
  type        = number
  default     = 80
}

variable "region" {
  description = "AWS region code. OneCloudify fills it from the region picked on the order."
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
  description = "Tags applied to every resource. OneCloudify passes the deployment tags here, including the onecloud_deployment correlation tag."
  type        = map(string)
  default     = {}
}
