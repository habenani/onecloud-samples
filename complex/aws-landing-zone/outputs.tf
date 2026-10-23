output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "subnet_ids" {
  description = "Subnet IDs by name"
  value       = module.subnets.ids
}

output "bucket" {
  description = "Configuration bucket"
  value       = aws_s3_bucket.config.id
}

output "settings_object" {
  description = "Object that lists the values Terraform received"
  value       = "s3://${aws_s3_bucket.config.id}/${aws_s3_object.settings.key}"
}

output "app_secret_sha256" {
  description = "SHA-256 of the application secret"
  value       = sha256(var.app_secret)
  sensitive   = true
}
