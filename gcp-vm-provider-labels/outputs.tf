output "instance_id" {
  description = "Path of the server, projects/<project>/zones/<zone>/instances/<name>"
  value       = google_compute_instance.server.id
}

output "private_ip" {
  description = "Internal IP address of the server"
  value       = google_compute_instance.server.network_interface[0].network_ip
}

output "labels" {
  description = "Labels on the server as Google holds them (the provider default labels OneCloudify added)"
  value       = google_compute_instance.server.effective_labels
}
