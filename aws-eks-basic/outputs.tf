output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.this.name
}

output "api_server" {
  description = "Endpoint of the Kubernetes API server"
  value       = aws_eks_cluster.this.endpoint
}

output "kubernetes_version" {
  description = "Kubernetes version of the control plane"
  value       = aws_eks_cluster.this.version
}

output "connect_command" {
  description = "Command that writes a kubeconfig for the cluster, for people with access to the account"
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${aws_eks_cluster.this.name}"
}
