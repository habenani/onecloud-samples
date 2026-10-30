data "vsphere_datacenter" "this" {
  name = var.datacenter
}

data "vsphere_resource_pool" "this" {
  name          = var.resource_pool
  datacenter_id = data.vsphere_datacenter.this.id
}

data "vsphere_datastore" "this" {
  name          = var.datastore
  datacenter_id = data.vsphere_datacenter.this.id
}

data "vsphere_network" "this" {
  name          = var.network
  datacenter_id = data.vsphere_datacenter.this.id
}

data "vsphere_virtual_machine" "template" {
  count         = var.template == "" ? 0 : 1
  name          = var.template
  datacenter_id = data.vsphere_datacenter.this.id
}

locals {
  clone = var.template != ""
  notes = join("\n", [for k in sort(keys(var.tags)) : "${k}=${var.tags[k]}"])
}

resource "vsphere_virtual_machine" "this" {
  name             = var.name
  resource_pool_id = data.vsphere_resource_pool.this.id
  datastore_id     = data.vsphere_datastore.this.id
  folder           = var.folder == "" ? null : var.folder
  num_cpus         = var.num_cpus
  memory           = var.memory_mb
  guest_id         = local.clone ? data.vsphere_virtual_machine.template[0].guest_id : var.guest_id
  scsi_type        = local.clone ? data.vsphere_virtual_machine.template[0].scsi_type : "pvscsi"
  annotation       = local.notes

  network_interface {
    network_id   = data.vsphere_network.this.id
    adapter_type = local.clone ? data.vsphere_virtual_machine.template[0].network_interface_types[0] : "vmxnet3"
  }

  disk {
    label            = "disk0"
    size             = var.disk_gb
    thin_provisioned = true
  }

  dynamic "clone" {
    for_each = local.clone ? [1] : []
    content {
      template_uuid = data.vsphere_virtual_machine.template[0].id
    }
  }

  # an empty VM has no VMware Tools to report an address; a cloned template with Tools does
  wait_for_guest_net_timeout = local.clone ? 5 : 0
  wait_for_guest_ip_timeout  = 0
}
