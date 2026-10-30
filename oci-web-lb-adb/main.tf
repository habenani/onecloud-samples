# Oracle Cloud web tier behind a load balancer, with a NAT gateway and an Autonomous Database, sample for OneCloudify.
# A VCN of its own with a public subnet for a flexible load balancer and a private subnet for the web servers (Oracle
# Linux 9 on flexible shapes, no public IP addresses) and the database. An internet gateway serves the load balancer,
# a NAT gateway lets the web servers reach the internet for updates, and an Autonomous Database (transaction
# processing, ECPU) has a private endpoint in the private subnet. One network security group per tier. Remove deletes
# all of it, the database too.
#
# Day-2 through OneCloudify: Resize through web_shape (shape:OCPUs:memory GB, every web server), Start, Stop and
# Restart of a web server through the OCI CLI on the MID Server. The database size is an order time choice.

locals {
  tags = merge(
    {
      Name        = var.name
      template    = "oci-web-lb-adb"
      cost_centre = var.cost_centre
    },
    var.test_tag == "" ? {} : { OneCloudTest = var.test_tag },
    var.tags,
  )
  # shape:OCPUs:memory GB
  web = { shape = split(":", var.web_shape)[0], ocpus = tonumber(split(":", var.web_shape)[1]), memory = tonumber(split(":", var.web_shape)[2]) }
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

# Oracle Linux 9 images that run on the web shape, newest first
data "oci_core_images" "web" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Oracle Linux"
  operating_system_version = "9"
  shape                    = local.web.shape
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

# OCI NAT gateways have no charge
resource "oci_core_nat_gateway" "this" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.name}-nat"
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

resource "oci_core_route_table" "private" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.name}-private"
  freeform_tags  = local.tags

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.this.id
  }
}

resource "oci_core_subnet" "public" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id
  cidr_block     = var.public_subnet_cidr
  display_name   = "${var.name}-public"
  dns_label      = "lb"
  route_table_id = oci_core_route_table.public.id
  freeform_tags  = merge(local.tags, { tier = "lb" })
}

resource "oci_core_subnet" "private" {
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.this.id
  cidr_block                 = var.private_subnet_cidr
  display_name               = "${var.name}-private"
  dns_label                  = "app"
  route_table_id             = oci_core_route_table.private.id
  prohibit_public_ip_on_vnic = true
  freeform_tags              = merge(local.tags, { tier = "web" })
}

# ------------------------------------------------------------------ network security groups

resource "oci_core_network_security_group" "lb" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.name}-lb"
  freeform_tags  = merge(local.tags, { tier = "lb" })
}

resource "oci_core_network_security_group_security_rule" "lb_ingress" {
  network_security_group_id = oci_core_network_security_group.lb.id
  description               = "Port ${var.web_port} from ${var.ingress_source_cidr}"
  direction                 = "INGRESS"
  protocol                  = "6"
  source_type               = "CIDR_BLOCK"
  source                    = var.ingress_source_cidr

  tcp_options {
    destination_port_range {
      min = var.web_port
      max = var.web_port
    }
  }
}

resource "oci_core_network_security_group_security_rule" "lb_egress" {
  network_security_group_id = oci_core_network_security_group.lb.id
  description               = "To the web servers"
  direction                 = "EGRESS"
  protocol                  = "6"
  destination_type          = "NETWORK_SECURITY_GROUP"
  destination               = oci_core_network_security_group.web.id
}

resource "oci_core_network_security_group" "web" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.name}-web"
  freeform_tags  = merge(local.tags, { tier = "web" })
}

resource "oci_core_network_security_group_security_rule" "web_ingress" {
  network_security_group_id = oci_core_network_security_group.web.id
  description               = "Port ${var.web_port} from the load balancer only"
  direction                 = "INGRESS"
  protocol                  = "6"
  source_type               = "NETWORK_SECURITY_GROUP"
  source                    = oci_core_network_security_group.lb.id

  tcp_options {
    destination_port_range {
      min = var.web_port
      max = var.web_port
    }
  }
}

resource "oci_core_network_security_group_security_rule" "web_egress" {
  network_security_group_id = oci_core_network_security_group.web.id
  description               = "Updates through the NAT gateway and the database"
  direction                 = "EGRESS"
  protocol                  = "all"
  destination_type          = "CIDR_BLOCK"
  destination               = "0.0.0.0/0"
}

resource "oci_core_network_security_group" "db" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.name}-db"
  freeform_tags  = merge(local.tags, { tier = "db" })
}

resource "oci_core_network_security_group_security_rule" "db_ingress" {
  network_security_group_id = oci_core_network_security_group.db.id
  description               = "Database (TLS 1522) from the web servers only"
  direction                 = "INGRESS"
  protocol                  = "6"
  source_type               = "NETWORK_SECURITY_GROUP"
  source                    = oci_core_network_security_group.web.id

  tcp_options {
    destination_port_range {
      min = 1522
      max = 1522
    }
  }
}

# ------------------------------------------------------------------ web servers

resource "oci_core_instance" "web" {
  count               = var.web_server_count
  compartment_id      = var.compartment_ocid
  availability_domain = data.oci_identity_availability_domains.this.availability_domains[count.index % length(data.oci_identity_availability_domains.this.availability_domains)].name
  display_name        = "${var.name}-web-${count.index + 1}"
  shape               = local.web.shape
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
    subnet_id        = oci_core_subnet.private.id
    assign_public_ip = false
    nsg_ids          = [oci_core_network_security_group.web.id]
    display_name     = "${var.name}-web-${count.index + 1}"
    freeform_tags    = merge(local.tags, { tier = "web" })
  }

  metadata = {
    user_data = base64encode(<<-EOT
      #!/bin/bash
      dnf install -y nginx
      echo "${var.name} web server ${count.index + 1}" > /usr/share/nginx/html/index.html
      sed -i 's/listen       80;/listen       ${var.web_port};/; s/listen       \[::\]:80;/listen       [::]:${var.web_port};/' /etc/nginx/nginx.conf
      firewall-offline-cmd --add-port=${var.web_port}/tcp
      systemctl enable --now nginx
      systemctl restart firewalld
    EOT
    )
  }

  # a newer image later must not rebuild the server
  lifecycle {
    ignore_changes = [source_details[0].source_id]
  }

  depends_on = [terraform_data.compartment_check, oci_core_nat_gateway.this]
}

# ------------------------------------------------------------------ load balancer

resource "oci_load_balancer_load_balancer" "web" {
  compartment_id             = var.compartment_ocid
  display_name               = "${var.name}-lb"
  shape                      = "flexible"
  subnet_ids                 = [oci_core_subnet.public.id]
  network_security_group_ids = [oci_core_network_security_group.lb.id]
  is_private                 = false
  freeform_tags              = merge(local.tags, { tier = "lb" })

  shape_details {
    minimum_bandwidth_in_mbps = var.lb_bandwidth_mbps
    maximum_bandwidth_in_mbps = var.lb_bandwidth_mbps
  }
}

resource "oci_load_balancer_backend_set" "web" {
  load_balancer_id = oci_load_balancer_load_balancer.web.id
  name             = "web"
  policy           = "ROUND_ROBIN"

  health_checker {
    protocol = "HTTP"
    port     = var.web_port
    url_path = "/"
  }
}

resource "oci_load_balancer_backend" "web" {
  count            = var.web_server_count
  load_balancer_id = oci_load_balancer_load_balancer.web.id
  backendset_name  = oci_load_balancer_backend_set.web.name
  ip_address       = oci_core_instance.web[count.index].private_ip
  port             = var.web_port
}

resource "oci_load_balancer_listener" "http" {
  load_balancer_id         = oci_load_balancer_load_balancer.web.id
  name                     = "http"
  default_backend_set_name = oci_load_balancer_backend_set.web.name
  port                     = var.web_port
  protocol                 = "HTTP"
}

# ------------------------------------------------------------------ database

# database names are letters and digits, unique in the region, so every order gets a suffix of its own
resource "random_string" "db" {
  length  = 4
  upper   = false
  special = false
}

# No admin password here: set it in the OCI Console (or with OCI Vault) when the team first connects, so no
# database secret is kept in Terraform state
resource "oci_database_autonomous_database" "db" {
  compartment_id              = var.compartment_ocid
  display_name                = "${var.name}-db"
  db_name                     = "${substr(replace(var.name, "-", ""), 0, 10)}${random_string.db.result}"
  db_workload                 = "OLTP"
  compute_model               = "ECPU"
  compute_count               = var.db_ecpu
  data_storage_size_in_gb     = var.db_storage_gb
  is_auto_scaling_enabled     = false
  license_model               = var.db_license_model
  database_edition            = var.db_license_model == "BRING_YOUR_OWN_LICENSE" ? "ENTERPRISE_EDITION" : null
  subnet_id                   = oci_core_subnet.private.id
  nsg_ids                     = [oci_core_network_security_group.db.id]
  private_endpoint_label      = substr("${replace(var.name, "-", "")}db", 0, 30)
  is_mtls_connection_required = false
  freeform_tags               = merge(local.tags, { tier = "db" })

  depends_on = [terraform_data.compartment_check]
}
