# Oracle Cloud three tier sample for OneCloudify.
# A VCN of its own with a public (web) and a private (app) subnet, an internet gateway for the web subnet only (no NAT
# gateway), a network security group per tier with one rule per web port, a web and an app server (Oracle Linux 9 on
# flexible shapes), block volumes on the app server and a private Object Storage bucket for app data.
#
# Day-2 through OneCloudify: variables named <tier>_<setting> belong to oci_core_instance.web or .app, so an operation
# run on one server changes only that server. Resize sets web_shape or app_shape (shape:OCPUs:memory GB, the same form
# the OCI CLI resize on the MID Server uses), Expand disk sets web_boot_volume_size_in_gbs or
# app_boot_volume_size_in_gbs, Add a data disk grows app_data_disk_sizes_gb, Open a port and Close a port change
# ingress_ports of the web tier, Start, Stop and Restart go through the OCI CLI on the MID Server.

locals {
  tags = merge(
    {
      Name        = var.name
      template    = "oci-three-tier"
      cost_centre = var.cost_centre
    },
    var.test_tag == "" ? {} : { OneCloudTest = var.test_tag },
    var.tags,
  )
  # shape:OCPUs:memory GB
  web = { shape = split(":", var.web_shape)[0], ocpus = tonumber(split(":", var.web_shape)[1]), memory = tonumber(split(":", var.web_shape)[2]) }
  app = { shape = split(":", var.app_shape)[0], ocpus = tonumber(split(":", var.app_shape)[1]), memory = tonumber(split(":", var.app_shape)[2]) }
  ssh = var.ssh_public_key == "" ? {} : { ssh_authorized_keys = var.ssh_public_key }
}

# the compartment comes from the cloud account; say so plainly when it is missing
resource "terraform_data" "compartment_check" {
  lifecycle {
    precondition {
      condition     = var.compartment_ocid != ""
      error_message = "compartment_ocid is empty. OneCloudify sets TF_VAR_compartment_ocid from the cloud account (placement defaults compartment_id, else the service account Account Id); hide the variable in the variable mapping so the empty default is not sent."
    }
  }
}

data "oci_identity_availability_domains" "this" {
  compartment_id = var.compartment_ocid
}

data "oci_objectstorage_namespace" "this" {
  compartment_id = var.compartment_ocid
}

# Oracle Linux 9 images that run on each tier's shape (Arm for A1, x86 for E4 and E5), newest first
data "oci_core_images" "web" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Oracle Linux"
  operating_system_version = "9"
  shape                    = local.web.shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

data "oci_core_images" "app" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Oracle Linux"
  operating_system_version = "9"
  shape                    = local.app.shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

# ------------------------------------------------------------------ network

resource "oci_core_vcn" "this" {
  compartment_id = var.compartment_ocid
  cidr_blocks    = [var.vcn_cidr]
  display_name   = "${var.name}-vcn"
  dns_label      = substr(replace(var.name, "-", ""), 0, 15)
  freeform_tags  = local.tags
}

resource "oci_core_internet_gateway" "this" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.name}-igw"
  enabled        = true
  freeform_tags  = local.tags
}

resource "oci_core_route_table" "public" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.name}-public"
  freeform_tags  = local.tags

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.this.id
  }
}

resource "oci_core_subnet" "public" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id
  cidr_block     = var.public_subnet_cidr
  display_name   = "${var.name}-public"
  dns_label      = "web"
  route_table_id = oci_core_route_table.public.id
  freeform_tags  = merge(local.tags, { tier = "web" })
}

# the private subnet keeps the VCN default route table: traffic inside the VCN only, no way out to the internet
resource "oci_core_subnet" "private" {
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.this.id
  cidr_block                 = var.private_subnet_cidr
  display_name               = "${var.name}-private"
  dns_label                  = "app"
  prohibit_public_ip_on_vnic = true
  freeform_tags              = merge(local.tags, { tier = "app" })
}

# ------------------------------------------------------------------ network security groups

resource "oci_core_network_security_group" "web" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.name}-web"
  freeform_tags  = merge(local.tags, { tier = "web" })
}

# one rule per port, so opening or closing one port leaves the others alone
resource "oci_core_network_security_group_security_rule" "web_ingress" {
  for_each                  = toset([for p in var.ingress_ports : tostring(p)])
  network_security_group_id = oci_core_network_security_group.web.id
  description               = "Port ${each.value} from ${var.ingress_source_cidr}"
  direction                 = "INGRESS"
  protocol                  = "6"
  source_type               = "CIDR_BLOCK"
  source                    = var.ingress_source_cidr

  tcp_options {
    destination_port_range {
      min = tonumber(each.value)
      max = tonumber(each.value)
    }
  }
}

resource "oci_core_network_security_group_security_rule" "web_egress" {
  network_security_group_id = oci_core_network_security_group.web.id
  description               = "All outbound"
  direction                 = "EGRESS"
  protocol                  = "all"
  destination_type          = "CIDR_BLOCK"
  destination               = "0.0.0.0/0"
}

resource "oci_core_network_security_group" "app" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.name}-app"
  freeform_tags  = merge(local.tags, { tier = "app" })
}

resource "oci_core_network_security_group_security_rule" "app_ingress" {
  network_security_group_id = oci_core_network_security_group.app.id
  description               = "App port from the web tier"
  direction                 = "INGRESS"
  protocol                  = "6"
  source_type               = "NETWORK_SECURITY_GROUP"
  source                    = oci_core_network_security_group.web.id

  tcp_options {
    destination_port_range {
      min = var.app_port
      max = var.app_port
    }
  }
}

resource "oci_core_network_security_group_security_rule" "app_egress" {
  network_security_group_id = oci_core_network_security_group.app.id
  description               = "Inside the VCN only"
  direction                 = "EGRESS"
  protocol                  = "all"
  destination_type          = "CIDR_BLOCK"
  destination               = var.vcn_cidr
}

# ------------------------------------------------------------------ servers

resource "oci_core_instance" "web" {
  compartment_id      = var.compartment_ocid
  availability_domain = data.oci_identity_availability_domains.this.availability_domains[0].name
  display_name        = "${var.name}-web"
  shape               = local.web.shape
  metadata            = local.ssh
  freeform_tags       = merge(local.tags, { tier = "web" })

  shape_config {
    ocpus         = local.web.ocpus
    memory_in_gbs = local.web.memory
  }

  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.web.images[0].id
    boot_volume_size_in_gbs = var.web_boot_volume_size_in_gbs
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.public.id
    assign_public_ip = true
    nsg_ids          = [oci_core_network_security_group.web.id]
    display_name     = "${var.name}-web"
    freeform_tags    = merge(local.tags, { tier = "web" })
  }

  # a newer image later must not rebuild the server
  lifecycle {
    ignore_changes = [source_details[0].source_id]
  }

  depends_on = [terraform_data.compartment_check]
}

resource "oci_core_instance" "app" {
  compartment_id      = var.compartment_ocid
  availability_domain = data.oci_identity_availability_domains.this.availability_domains[0].name
  display_name        = "${var.name}-app"
  shape               = local.app.shape
  metadata            = local.ssh
  freeform_tags       = merge(local.tags, { tier = "app" })

  shape_config {
    ocpus         = local.app.ocpus
    memory_in_gbs = local.app.memory
  }

  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.app.images[0].id
    boot_volume_size_in_gbs = var.app_boot_volume_size_in_gbs
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.private.id
    assign_public_ip = false
    nsg_ids          = [oci_core_network_security_group.app.id]
    display_name     = "${var.name}-app"
    freeform_tags    = merge(local.tags, { tier = "app" })
  }

  lifecycle {
    ignore_changes = [source_details[0].source_id]
  }

  depends_on = [terraform_data.compartment_check]
}

resource "oci_core_volume" "app_data" {
  count               = length(var.app_data_disk_sizes_gb)
  compartment_id      = var.compartment_ocid
  availability_domain = oci_core_instance.app.availability_domain
  display_name        = "${var.name}-app-data-${count.index}"
  size_in_gbs         = var.app_data_disk_sizes_gb[count.index]
  freeform_tags       = merge(local.tags, { tier = "app" })
}

resource "oci_core_volume_attachment" "app_data" {
  count           = length(var.app_data_disk_sizes_gb)
  attachment_type = "paravirtualized"
  instance_id     = oci_core_instance.app.id
  volume_id       = oci_core_volume.app_data[count.index].id
  display_name    = "${var.name}-app-data-${count.index}"
}

# ------------------------------------------------------------------ storage

resource "oci_objectstorage_bucket" "data" {
  compartment_id = var.compartment_ocid
  namespace      = data.oci_objectstorage_namespace.this.namespace
  name           = "${var.name}-data"
  access_type    = "NoPublicAccess"
  storage_tier   = "Standard"
  freeform_tags  = local.tags
}
