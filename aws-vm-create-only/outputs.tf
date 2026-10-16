output "instance_id" {
  description = "EC2 instance id"
  value       = aws_instance.vm.id
}

output "private_ip" {
  description = "Private IP address"
  value       = aws_instance.vm.private_ip
}

output "public_ip" {
  description = "Public IP address, empty when the default subnet gives none"
  value       = aws_instance.vm.public_ip
}

output "availability_zone" {
  description = "Availability zone the instance runs in"
  value       = aws_instance.vm.availability_zone
}
