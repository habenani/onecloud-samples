# Google Cloud three tier sample for OneCloud.
# A VPC network of its own with a web and an app subnet, one firewall rule per web port, a web server with an
# external IP address and an app server without one (Debian 12), persistent data disks on the app server and a private
# Cloud Storage bucket for app data. Remove deletes all of it, the bucket with its objects included.
#
# Day-2 through OneCloud: variables named <tier>_<setting> belong to google_compute_instance.web or .app, so an
# operation run on one server changes only that server (Resize through web_machine_type and app_machine_type, Expand
# disk through web_boot_disk_size and app_boot_disk_size). Add a data disk grows app_data_disk_sizes_gb, Open a port
# and Close a port change ingress_ports of the web tier (one firewall rule each), Start, Stop and Restart go through
# gcloud on the MID Server.

locals {
  zone = "${var.region}-${var.zone_suffix}"
  # Google label keys and values: lower case letters, digits, underscores and hyphens, at most 63 characters
  raw_labels = merge(
    {
      name        = var.name
      template    = "gcp-three-tier"
      cost_centre = var.cost_centre
    },
    var.test_tag == "" ? {} : { onecloudtest = var.test_tag },
    var.tags,
  )
  labels = {
    for k, v in local.raw_labels :
    substr(lower(replace(k, "/[^A-Za-z0-9_-]/", "_")), 0, 63) => substr(lower(replace(v, "/[^A-Za-z0-9_-]/", "_")), 0, 63)
  }
  web_tag = "${var.name}-web"
  app_tag = "${var.name}-app"
  ssh_key = var.ssh_public_key == "" ? {} : { ssh-keys = "onecloud:${var.ssh_public_key}" }
}

data "google_compute_image" "debian" {
  family  = "debian-12"
  project = "debian-cloud"
}

# ------------------------------------------------------------------ network

resource "google_compute_network" "this" {
  name                    = "${var.name}-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "web" {
  name          = "${var.name}-web"
  ip_cidr_range = var.web_subnet_cidr
  region        = var.region
  network       = google_compute_network.this.id
}

resource "google_compute_subnetwork" "app" {
  name                     = "${var.name}-app"
  ip_cidr_range            = var.app_subnet_cidr
  region                   = var.region
  network                  = google_compute_network.this.id
  private_ip_google_access = true
}

# one rule per port, so opening or closing one port leaves the others alone
resource "google_compute_firewall" "web" {
  for_each      = toset([for p in var.ingress_ports : tostring(p)])
  name          = "${var.name}-web-${each.value}"
  network       = google_compute_network.this.name
  description   = "Port ${each.value} from ${var.ingress_source_cidr}"
  direction     = "INGRESS"
  source_ranges = [var.ingress_source_cidr]
  target_tags   = [local.web_tag]

  allow {
    protocol = "tcp"
    ports    = [each.value]
  }
}

resource "google_compute_firewall" "app" {
  name        = "${var.name}-app-${var.app_port}"
  network     = google_compute_network.this.name
  description = "App port from the web servers only"
  direction   = "INGRESS"
  source_tags = [local.web_tag]
  target_tags = [local.app_tag]

  allow {
    protocol = "tcp"
    ports    = [tostring(var.app_port)]
  }
}

resource "google_compute_address" "web" {
  name   = "${var.name}-web-ip"
  region = var.region
  labels = local.labels
}

# ------------------------------------------------------------------ servers

resource "google_compute_instance" "web" {
  name         = "${var.name}-web"
  machine_type = var.web_machine_type
  zone         = local.zone
  tags         = [local.web_tag]
  labels       = merge(local.labels, { tier = "web" })
  metadata     = local.ssh_key

  # a new machine type needs the server stopped: Terraform stops and starts it
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image  = data.google_compute_image.debian.self_link
      size   = var.web_boot_disk_size
      type   = "pd-balanced"
      labels = merge(local.labels, { tier = "web" })
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.web.id

    access_config {
      nat_ip = google_compute_address.web.address
    }
  }

  shielded_instance_config {
    enable_secure_boot = true
  }
}

resource "google_compute_instance" "app" {
  name         = "${var.name}-app"
  machine_type = var.app_machine_type
  zone         = local.zone
  tags         = [local.app_tag]
  labels       = merge(local.labels, { tier = "app" })
  metadata     = local.ssh_key

  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image  = data.google_compute_image.debian.self_link
      size   = var.app_boot_disk_size
      type   = "pd-balanced"
      labels = merge(local.labels, { tier = "app" })
    }
  }

  # no access_config: no external IP address, so no way in or out from the internet
  network_interface {
    subnetwork = google_compute_subnetwork.app.id
  }

  shielded_instance_config {
    enable_secure_boot = true
  }

  # the data disks are attached by google_compute_attached_disk below
  lifecycle {
    ignore_changes = [attached_disk]
  }
}

resource "google_compute_disk" "app_data" {
  count  = length(var.app_data_disk_sizes_gb)
  name   = "${var.name}-app-data-${count.index}"
  zone   = local.zone
  size   = var.app_data_disk_sizes_gb[count.index]
  type   = "pd-balanced"
  labels = merge(local.labels, { tier = "app" })
}

resource "google_compute_attached_disk" "app_data" {
  count    = length(var.app_data_disk_sizes_gb)
  disk     = google_compute_disk.app_data[count.index].id
  instance = google_compute_instance.app.id
}

# ------------------------------------------------------------------ storage

resource "google_storage_bucket" "data" {
  name                        = "${var.name}-data-${random_id.bucket.hex}"
  location                    = upper(var.region)
  force_destroy               = true
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  labels                      = local.labels
}

resource "random_id" "bucket" {
  byte_length = 4
}
