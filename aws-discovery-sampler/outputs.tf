output "vpc_id" {
  description = "Id of the sampler VPC"
  value       = aws_vpc.this.id
}

output "instance_id" {
  description = "Id of the EC2 instance"
  value       = aws_instance.this.id
}

output "load_balancer_dns" {
  description = "DNS name of the internal application load balancer"
  value       = aws_lb.this.dns_name
}

output "database_endpoint" {
  description = "Endpoint of the RDS PostgreSQL instance"
  value       = aws_db_instance.this.address
}
