output "vcn_id" {
  description = "OCID of the VCN"
  value       = oci_core_vcn.this.id
}

output "load_balancer_ip" {
  description = "Public IP address of the load balancer"
  value       = oci_load_balancer_load_balancer.web.ip_address_details[0].ip_address
}

output "web_url" {
  description = "Address of the web tier through the load balancer"
  value       = "http://${oci_load_balancer_load_balancer.web.ip_address_details[0].ip_address}${var.web_port == 80 ? "" : ":${var.web_port}"}"
}

output "web_private_ips" {
  description = "Private IP addresses of the web servers"
  value       = oci_core_instance.web[*].private_ip
}

output "web_instance_ids" {
  description = "OCIDs of the web servers"
  value       = oci_core_instance.web[*].id
}

output "nat_gateway_id" {
  description = "OCID of the NAT gateway"
  value       = oci_core_nat_gateway.this.id
}

output "db_id" {
  description = "OCID of the Autonomous Database"
  value       = oci_database_autonomous_database.db.id
}

output "db_private_endpoint" {
  description = "Private endpoint of the Autonomous Database, reachable from the web servers"
  value       = oci_database_autonomous_database.db.private_endpoint
}
