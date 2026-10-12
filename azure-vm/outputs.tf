output "vm_id" {
  description = "Azure resource id of the virtual machine"
  value       = azurerm_linux_virtual_machine.this.id
}

output "private_ip" {
  description = "Private IP address of the primary network interface"
  value       = azurerm_network_interface.this.private_ip_address
}

output "public_ip" {
  description = "Public IP address, empty when create_public_ip is false"
  value       = try(azurerm_public_ip.this[0].ip_address, "")
}

output "resource_group" {
  description = "Resource group that holds the virtual machine"
  value       = local.resource_group_name
}
