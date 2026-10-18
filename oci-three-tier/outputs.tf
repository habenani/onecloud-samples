output "vcn_id" {
  description = "OCID of the VCN"
  value       = oci_core_vcn.this.id
}

output "web_public_ip" {
  description = "Public IP address of the web server"
  value       = oci_core_instance.web.public_ip
}

output "web_private_ip" {
  description = "Private IP address of the web server"
  value       = oci_core_instance.web.private_ip
}

output "app_private_ip" {
  description = "Private IP address of the app server"
  value       = oci_core_instance.app.private_ip
}

output "web_instance_id" {
  description = "OCID of the web server"
  value       = oci_core_instance.web.id
}

output "app_instance_id" {
  description = "OCID of the app server"
  value       = oci_core_instance.app.id
}

output "data_bucket" {
  description = "Name of the private Object Storage bucket"
  value       = oci_objectstorage_bucket.data.name
}

output "open_ports" {
  description = "TCP ports the web tier accepts"
  value       = sort(var.ingress_ports)
}

output "web_url" {
  description = "Address of the web server"
  value       = "http://${oci_core_instance.web.public_ip}"
}
