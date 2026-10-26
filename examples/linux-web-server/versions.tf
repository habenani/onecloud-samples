# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0
# Changed by Intelibliss for OneCloudify: provider range of the other OneCloudify samples, no lock file shipped.

terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0, < 7.0"
    }
  }
}

# The access key comes from the environment OneCloudify exports on the runner. Nothing is hardcoded here on purpose.
provider "aws" {
  region = var.region
}
