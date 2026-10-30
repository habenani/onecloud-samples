output "vm_id" {
  description = "Instance UUID of the virtual machine (what OneCloudify power actions and govc use)"
  value       = vsphere_virtual_machine.this.uuid
}

output "moid" {
  description = "Managed object id of the virtual machine (vm-123, what Discovery keeps)"
  value       = vsphere_virtual_machine.this.moid
}

output "private_ip" {
  description = "Guest IP address VMware Tools reports, empty without Tools"
  value       = vsphere_virtual_machine.this.default_ip_address
}
