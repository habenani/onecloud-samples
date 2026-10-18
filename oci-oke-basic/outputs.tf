output "cluster_name" {
  description = "Name of the OKE cluster"
  value       = oci_containerengine_cluster.this.name
}

output "cluster_id" {
  description = "OCID of the OKE cluster"
  value       = oci_containerengine_cluster.this.id
}

output "api_server" {
  description = "Public address of the Kubernetes API endpoint"
  value       = oci_containerengine_cluster.this.endpoints[0].public_endpoint
}

output "kubernetes_version" {
  description = "Kubernetes version the control plane runs"
  value       = oci_containerengine_cluster.this.kubernetes_version
}

output "node_count" {
  description = "Number of worker nodes in the node pool"
  value       = var.node_count
}

output "connect_command" {
  description = "Command that writes a kubeconfig for kubectl, for people with access to the compartment"
  value       = "oci ce cluster create-kubeconfig --cluster-id ${oci_containerengine_cluster.this.id} --region ${var.region} --token-version 2.0.0 --kube-endpoint PUBLIC_ENDPOINT"
}
