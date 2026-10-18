output "network" {
  description = "Name of the VPC network"
  value       = google_compute_network.this.name
}

output "web_public_ip" {
  description = "External IP address of the web server"
  value       = google_compute_address.web.address
}

output "web_private_ip" {
  description = "Internal IP address of the web server"
  value       = google_compute_instance.web.network_interface[0].network_ip
}

output "app_private_ip" {
  description = "Internal IP address of the app server"
  value       = google_compute_instance.app.network_interface[0].network_ip
}

output "web_instance_id" {
  description = "Path of the web server, projects/<project>/zones/<zone>/instances/<name>"
  value       = google_compute_instance.web.id
}

output "app_instance_id" {
  description = "Path of the app server"
  value       = google_compute_instance.app.id
}

output "data_bucket" {
  description = "Name of the private Cloud Storage bucket"
  value       = google_storage_bucket.data.name
}

output "open_ports" {
  description = "TCP ports the web tier accepts"
  value       = sort(var.ingress_ports)
}

output "web_url" {
  description = "Address of the web server"
  value       = "http://${google_compute_address.web.address}"
}
