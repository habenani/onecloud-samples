terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0, < 7.0"
    }
  }
}

provider "aws" {
  region = var.region
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-north-1"
}

variable "bucket_prefix" {
  description = "Start of the bucket name"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{2,30}$", var.bucket_prefix))
    error_message = "Use 3 to 31 lower case letters, digits or hyphens."
  }
}

resource "aws_s3_bucket" "this" {
  bucket_prefix = "${var.bucket_prefix}-"
  force_destroy = true
  tags          = merge(var.tags, { storage_class = var.storage_class })
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
