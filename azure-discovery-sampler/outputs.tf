output "resource_group" {
  description = "Resource group that holds the sampler"
  value       = azurerm_resource_group.this.name
}

output "vm_id" {
  description = "Azure resource id of the virtual machine"
  value       = azurerm_linux_virtual_machine.this.id
}

output "sql_server" {
  description = "Fully qualified name of the Azure SQL server"
  value       = azurerm_mssql_server.this.fully_qualified_domain_name
}

output "load_balancer_ip" {
  description = "Public IP address of the load balancer frontend"
  value       = azurerm_public_ip.lb.ip_address
}
