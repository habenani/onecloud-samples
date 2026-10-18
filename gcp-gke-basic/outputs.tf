output "cluster_name" {
  description = "Name of the GKE cluster"
  value       = google_container_cluster.this.name
}

output "location" {
  description = "Zone of the cluster"
  value       = google_container_cluster.this.location
}

output "api_server" {
  description = "Address of the Kubernetes API server"
  value       = google_container_cluster.this.endpoint
}

output "kubernetes_version" {
  description = "Kubernetes version the control plane runs"
  value       = google_container_cluster.this.master_version
}

output "node_count" {
  description = "Number of nodes in the node pool"
  value       = google_container_node_pool.this.node_count
}

output "connect_command" {
  description = "Command that gets the cluster credentials for kubectl, for people with access to the project"
  value       = "gcloud container clusters get-credentials ${google_container_cluster.this.name} --zone ${google_container_cluster.this.location}"
}
