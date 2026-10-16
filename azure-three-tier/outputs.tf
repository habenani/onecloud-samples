output "resource_group" {
  description = "Resource group that holds everything this deployment made"
  value       = azurerm_resource_group.this.name
}

output "web_public_ip" {
  description = "Public IP address of the web server"
  value       = azurerm_public_ip.web.ip_address
}

output "web_private_ip" {
  description = "Private IP address of the web server"
  value       = azurerm_network_interface.web.private_ip_address
}

output "app_private_ip" {
  description = "Private IP address of the app server"
  value       = azurerm_network_interface.app.private_ip_address
}

output "web_vm_id" {
  description = "Azure resource id of the web server"
  value       = azurerm_linux_virtual_machine.web.id
}

output "app_vm_id" {
  description = "Azure resource id of the app server"
  value       = azurerm_linux_virtual_machine.app.id
}

output "storage_account_name" {
  description = "Storage account for app data (no public network access)"
  value       = azurerm_storage_account.app.name
}

output "open_ports" {
  description = "TCP ports the web tier accepts"
  value       = sort(var.ingress_ports)
}
