output "resource_group_id" {
  description = "Resource group id"
  value       = azurerm_resource_group.this.id
}

output "storage_account_id" {
  description = "Storage account id, empty when not created"
  value       = try(azurerm_storage_account.this[0].id, "")
}
