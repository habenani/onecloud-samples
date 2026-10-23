terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0, < 7.0"
    }
  }
}

# Credentials come from the environment the runner exports (nothing hard coded).
provider "aws" {
  region = var.region
}
