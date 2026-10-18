# Create S3 bucket resource
resource "aws_s3_bucket" "my_bucket" {
  bucket = var.bucket_name
}
resource "aws_s3_bucket_public_access_block" "s3_block_public_access" {
  bucket = aws_s3_bucket.my_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.my_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.encryption_key_type
      kms_master_key_id = (var.encryption_key_type=="aws:kms") ? var.encryption_kms_key : null    
    }
    bucket_key_enabled = (var.encryption_key_type=="aws:kms")? var.bucket_key : false
  }
}
