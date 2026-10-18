output "vpc_id" {
  description = "Id of the VPC."
  value       = aws_vpc.this.id
}

output "web_public_ip" {
  description = "Public IPv4 address of the web server (changes after a Stop and Start)."
  value       = aws_instance.web.public_ip
}

output "web_private_ip" {
  description = "Private IPv4 address of the web server."
  value       = aws_instance.web.private_ip
}

output "app_private_ip" {
  description = "Private IPv4 address of the app server."
  value       = aws_instance.app.private_ip
}

output "web_instance_id" {
  description = "EC2 instance id of the web server."
  value       = aws_instance.web.id
}

output "app_instance_id" {
  description = "EC2 instance id of the app server."
  value       = aws_instance.app.id
}

output "data_bucket" {
  description = "Name of the private S3 bucket for app data."
  value       = aws_s3_bucket.data.bucket
}

output "open_ports" {
  description = "TCP ports open on the web tier."
  value       = var.ingress_ports
}

output "web_url" {
  description = "Address of the web server over plain HTTP (port 80 must be open)."
  value       = "http://${aws_instance.web.public_ip}"
}
