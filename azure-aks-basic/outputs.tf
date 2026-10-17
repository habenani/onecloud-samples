output "cluster_name" {
  description = "Name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.this.name
}

output "resource_group" {
  description = "Resource group of the cluster"
  value       = azurerm_resource_group.this.name
}

output "node_resource_group" {
  description = "Resource group Azure keeps the nodes in, deleted with the cluster"
  value       = azurerm_kubernetes_cluster.this.node_resource_group
}

output "api_server" {
  description = "Host name of the Kubernetes API server"
  value       = azurerm_kubernetes_cluster.this.fqdn
}

output "kubernetes_version" {
  description = "Kubernetes version the control plane runs"
  value       = azurerm_kubernetes_cluster.this.current_kubernetes_version
}

output "connect_command" {
  description = "Command that gets the cluster credentials for kubectl, for people with access to the subscription"
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.this.name} --name ${azurerm_kubernetes_cluster.this.name}"
}
