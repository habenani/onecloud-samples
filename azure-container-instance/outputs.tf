output "container_group" {
  description = "Name of the container group"
  value       = azurerm_container_group.this.name
}

output "resource_group" {
  description = "Resource group of the container group"
  value       = azurerm_resource_group.this.name
}

output "url" {
  description = "Address of the container on the internet"
  value       = "http://${azurerm_container_group.this.fqdn}${var.port == 80 ? "" : ":${var.port}"}"
}

output "public_ip" {
  description = "Public IP address. It can change when the containers are stopped and started or restarted"
  value       = azurerm_container_group.this.ip_address
}

output "image" {
  description = "Container image that runs"
  value       = var.image
}
