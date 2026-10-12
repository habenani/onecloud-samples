terraform {
  required_version = ">= 1.3"
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.4"
    }
  }
}

resource "random_pet" "name" {
  length    = var.name_length
  prefix    = var.prefix
  separator = "-"
}

resource "random_integer" "port" {
  min = 1024
  max = 65535
}

resource "local_file" "marker" {
  content  = "${random_pet.name.id} ${var.environment} ${jsonencode(var.tags)}\n"
  filename = "${path.module}/.onecloud/${random_pet.name.id}.txt"
}
