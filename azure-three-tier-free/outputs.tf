output "web_url" {
  description = "Address of the web tier behind the load balancer"
  value       = "http://${azurerm_public_ip.lb.ip_address}"
}

output "db_host" {
  description = "Host name of the database server"
  value       = azurerm_postgresql_flexible_server.db.fqdn
}

output "resource_group" {
  description = "Resource group of the deployment"
  value       = azurerm_resource_group.this.name
}
