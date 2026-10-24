# Oracle Container Engine for Kubernetes (OKE) basic sample for OneCloudify.
# A basic cluster (no cluster fee) with a public Kubernetes API endpoint and one managed node pool of 1 to 3 worker
# nodes on a flexible shape, in a VCN of its own: an endpoint subnet and a node subnet behind an internet gateway.
#
# Day-2 through OneCloudify: Scale node pool sets node_count, Upgrade Kubernetes version sets kubernetes_version (control
# plane and node pool; OKE replaces nodes as they are cycled), Update changes the other order form settings.

locals {
  tags = merge(
    {
      Name        = var.name
      template    = "oci-oke-basic"
      cost_centre = var.cost_centre
    },
    var.test_tag == "" ? {} : { OneCloudTest = var.test_tag },
    var.tags,
  )
  node = { shape = split(":", var.node_shape)[0], ocpus = tonumber(split(":", var.node_shape)[1]), memory = tonumber(split(":", var.node_shape)[2]) }
  # the newest patch OKE offers for the minor version (sorted by patch number, not as text)
  offered       = [for v in data.oci_containerengine_cluster_option.this.kubernetes_versions : v if startswith(v, "v${var.kubernetes_version}.")]
  ranked        = sort([for v in local.offered : format("%05d|%s", tonumber(split(".", v)[2]), v)])
  version       = length(local.ranked) == 0 ? "v${var.kubernetes_version}.1" : split("|", local.ranked[length(local.ranked) - 1])[1]
  endpoint_cidr = cidrsubnet(var.vcn_cidr, 12, 0)
  node_cidr     = cidrsubnet(var.vcn_cidr, 8, 2)
}

resource "terraform_data" "compartment_check" {
  lifecycle {
    precondition {
      condition     = var.compartment_ocid != ""
      error_message = "compartment_ocid is empty. OneCloudify sets TF_VAR_compartment_ocid from the cloud account; hide the variable in the variable mapping so the empty default is not sent."
    }
  }
}

data "oci_containerengine_cluster_option" "this" {
  cluster_option_id = "all"
  compartment_id    = var.compartment_ocid
}

data "oci_identity_availability_domains" "this" {
  compartment_id = var.compartment_ocid
}

data "oci_core_images" "node" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Oracle Linux"
  operating_system_version = "8"
  shape                    = local.node.shape
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

resource "oci_core_route_table" "this" {
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

resource "oci_core_security_list" "endpoint" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.name}-endpoint"
  freeform_tags  = local.tags

  ingress_security_rules {
    description = "Kubernetes API from api_source_cidr"
    protocol    = "6"
    source      = var.api_source_cidr

    tcp_options {
      min = 6443
      max = 6443
    }
  }

  ingress_security_rules {
    description = "Worker nodes to the control plane"
    protocol    = "6"
    source      = local.node_cidr

    tcp_options {
      min = 12250
      max = 12250
    }
  }

  egress_security_rules {
    description = "Control plane to the worker nodes"
    protocol    = "all"
    destination = local.node_cidr
  }
}

resource "oci_core_security_list" "nodes" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.name}-nodes"
  freeform_tags  = local.tags

  ingress_security_rules {
    description = "Traffic inside the VCN (pods, control plane)"
    protocol    = "all"
    source      = var.vcn_cidr
  }

  ingress_security_rules {
    description = "Path MTU discovery"
    protocol    = "1"
    source      = "0.0.0.0/0"

    icmp_options {
      type = 3
      code = 4
    }
  }

  egress_security_rules {
    description = "All outbound (images, OCI services)"
    protocol    = "all"
    destination = "0.0.0.0/0"
  }
}

resource "oci_core_subnet" "endpoint" {
  compartment_id    = var.compartment_ocid
  vcn_id            = oci_core_vcn.this.id
  cidr_block        = local.endpoint_cidr
  display_name      = "${var.name}-endpoint"
  dns_label         = "endpoint"
  route_table_id    = oci_core_route_table.this.id
  security_list_ids = [oci_core_security_list.endpoint.id]
  freeform_tags     = local.tags
}

resource "oci_core_subnet" "nodes" {
  compartment_id    = var.compartment_ocid
  vcn_id            = oci_core_vcn.this.id
  cidr_block        = local.node_cidr
  display_name      = "${var.name}-nodes"
  dns_label         = "nodes"
  route_table_id    = oci_core_route_table.this.id
  security_list_ids = [oci_core_security_list.nodes.id]
  freeform_tags     = local.tags
}

# ------------------------------------------------------------------ cluster

resource "oci_containerengine_cluster" "this" {
  compartment_id     = var.compartment_ocid
  name               = var.name
  vcn_id             = oci_core_vcn.this.id
  kubernetes_version = local.version
  type               = "BASIC_CLUSTER"
  freeform_tags      = local.tags

  endpoint_config {
    subnet_id            = oci_core_subnet.endpoint.id
    is_public_ip_enabled = true
  }

  cluster_pod_network_options {
    cni_type = "FLANNEL_OVERLAY"
  }

  options {
    kubernetes_network_config {
      pods_cidr     = "10.244.0.0/16"
      services_cidr = "10.96.0.0/16"
    }
  }

  depends_on = [terraform_data.compartment_check]
}

resource "oci_containerengine_node_pool" "this" {
  compartment_id     = var.compartment_ocid
  cluster_id         = oci_containerengine_cluster.this.id
  name               = "${var.name}-pool"
  kubernetes_version = local.version
  node_shape         = local.node.shape
  freeform_tags      = local.tags

  node_shape_config {
    ocpus         = local.node.ocpus
    memory_in_gbs = local.node.memory
  }

  node_source_details {
    source_type = "IMAGE"
    image_id    = data.oci_core_images.node.images[0].id
  }

  node_config_details {
    size          = var.node_count
    freeform_tags = local.tags

    placement_configs {
      availability_domain = data.oci_identity_availability_domains.this.availability_domains[0].name
      subnet_id           = oci_core_subnet.nodes.id
    }
  }

  lifecycle {
    ignore_changes = [node_source_details[0].image_id]
  }
}
