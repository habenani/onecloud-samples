output "pet_name" {
  description = "The generated name"
  value       = random_pet.name.id
}

output "port" {
  description = "A random port"
  value       = random_integer.port.result
}

output "marker_path" {
  description = "Path of the marker file"
  value       = local_file.marker.filename
}

output "secret_echo" {
  description = "Sensitive outputs are never shown to requesters"
  value       = var.admin_token
  sensitive   = true
}
