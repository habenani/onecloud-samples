terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0, < 7.0"
    }
  }
}

# The access key comes from the environment OneCloud exports on the runner (AWS_ACCESS_KEY_ID and
# AWS_SECRET_ACCESS_KEY from the cloud account credential). Nothing is hardcoded here on purpose.
provider "aws" {
  region = var.region
}
