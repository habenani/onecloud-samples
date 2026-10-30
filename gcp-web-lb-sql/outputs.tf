output "network" {
  description = "Name of the VPC network"
  value       = google_compute_network.this.name
}

output "load_balancer_ip" {
  description = "External IP address of the load balancer"
  value       = google_compute_forwarding_rule.web.ip_address
}

output "web_url" {
  description = "Address of the web tier through the load balancer"
  value       = "http://${google_compute_forwarding_rule.web.ip_address}${var.web_port == 80 ? "" : ":${var.web_port}"}"
}

output "web_private_ips" {
  description = "Internal IP addresses of the web servers"
  value       = google_compute_instance.web[*].network_interface[0].network_ip
}

output "web_instance_ids" {
  description = "Paths of the web servers, projects/<project>/zones/<zone>/instances/<name>"
  value       = google_compute_instance.web[*].id
}

output "nat_name" {
  description = "Name of the Cloud NAT gateway"
  value       = google_compute_router_nat.this.name
}

output "db_connection_name" {
  description = "Connection name of the Cloud SQL instance, for the Cloud SQL Auth Proxy"
  value       = google_sql_database_instance.db.connection_name
}

output "db_public_ip" {
  description = "Public IP address of the Cloud SQL instance (no authorised networks: connect through the Auth Proxy)"
  value       = google_sql_database_instance.db.public_ip_address
}
