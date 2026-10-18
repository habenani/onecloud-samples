# Declare input variables
variable "access_key" {}
variable "secret_key" {}
variable "region" {}
variable "bucket_name" {
  description = "S3 bucket name"
}
variable "encryption_kms_key" {
    default = "aws/s3"
    description = "Flag to enable server-side encryption"
}
variable "encryption_key_type" {
    default = "AES256"
}
variable "bucket_key" {
  default=false
}
