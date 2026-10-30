# Google Cloud web tier behind a load balancer, with Cloud NAT and a Cloud SQL database, sample for OneCloudify.
# A VPC network of its own with one subnet, web servers without external IP addresses (Debian 12 with nginx) in an
# unmanaged instance group, a regional external passthrough network load balancer in front of them (health check,
# backend service, forwarding rule), a Cloud Router with Cloud NAT so the servers reach the internet for updates, and a
# Cloud SQL instance (PostgreSQL or MySQL, Enterprise edition) with a public IP address, no authorised networks and
# encrypted connections only (connect through the Cloud SQL Auth Proxy). Remove deletes all of it, the database too.
#
# Day-2 through OneCloudify: Resize through web_machine_type (every web server), Start, Stop and Restart of a web server
# through gcloud on the MID Server. The database tier, storage and availability are order time choices.

locals {
  zone = "${var.region}-${var.zone_suffix}"
  # Google label keys and values: lower case letters, digits, underscores and hyphens, at most 63 characters
  raw_labels = merge(
    {
      name        = var.name
      template    = "gcp-web-lb-sql"
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
  name                     = "${var.name}-web"
  ip_cidr_range            = var.subnet_cidr
  region                   = var.region
  network                  = google_compute_network.this.id
  private_ip_google_access = true
}

# a passthrough load balancer keeps the client address, so the web port is opened to the clients themselves
resource "google_compute_firewall" "web" {
  name          = "${var.name}-web-${var.web_port}"
  network       = google_compute_network.this.name
  description   = "Port ${var.web_port} from ${var.ingress_source_cidr}"
  direction     = "INGRESS"
  source_ranges = [var.ingress_source_cidr]
  target_tags   = [local.web_tag]

  allow {
    protocol = "tcp"
    ports    = [tostring(var.web_port)]
  }
}

# Google's health check probes for network load balancers
resource "google_compute_firewall" "health" {
  name          = "${var.name}-health"
  network       = google_compute_network.this.name
  description   = "Load balancer health checks"
  direction     = "INGRESS"
  source_ranges = ["35.191.0.0/16", "209.85.152.0/22", "209.85.204.0/22"]
  target_tags   = [local.web_tag]

  allow {
    protocol = "tcp"
    ports    = [tostring(var.web_port)]
  }
}

# ------------------------------------------------------------------ Cloud NAT

resource "google_compute_router" "this" {
  name    = "${var.name}-router"
  region  = var.region
  network = google_compute_network.this.id
}

resource "google_compute_router_nat" "this" {
  name                               = "${var.name}-nat"
  router                             = google_compute_router.this.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# ------------------------------------------------------------------ web servers

resource "google_compute_instance" "web" {
  count        = var.web_server_count
  name         = "${var.name}-web-${count.index + 1}"
  machine_type = var.web_machine_type
  zone         = local.zone
  tags         = [local.web_tag]
  labels       = merge(local.labels, { tier = "web" })

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

  # no access_config: no external IP address. The load balancer brings traffic in, Cloud NAT takes updates out
  network_interface {
    subnetwork = google_compute_subnetwork.web.id
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    apt-get update -y && apt-get install -y nginx
    echo "${var.name} web server ${count.index + 1}" > /var/www/html/index.html
    sed -i 's/listen 80 default_server;/listen ${var.web_port} default_server;/; s/listen \[::\]:80 default_server;/listen [::]:${var.web_port} default_server;/' /etc/nginx/sites-enabled/default
    systemctl restart nginx
  EOT

  shielded_instance_config {
    enable_secure_boot = true
  }

  # the servers wait for Cloud NAT, or the startup script finds no way out
  depends_on = [google_compute_router_nat.this]
}

resource "google_compute_instance_group" "web" {
  name      = "${var.name}-web"
  zone      = local.zone
  instances = google_compute_instance.web[*].self_link

  named_port {
    name = "http"
    port = var.web_port
  }
}

# ------------------------------------------------------------------ load balancer

resource "google_compute_region_health_check" "web" {
  name   = "${var.name}-web"
  region = var.region

  tcp_health_check {
    port = var.web_port
  }
}

resource "google_compute_region_backend_service" "web" {
  name                  = "${var.name}-web"
  region                = var.region
  protocol              = "TCP"
  load_balancing_scheme = "EXTERNAL"
  health_checks         = [google_compute_region_health_check.web.id]

  backend {
    group          = google_compute_instance_group.web.id
    balancing_mode = "CONNECTION"
  }
}

resource "google_compute_forwarding_rule" "web" {
  name                  = "${var.name}-web"
  region                = var.region
  load_balancing_scheme = "EXTERNAL"
  ip_protocol           = "TCP"
  port_range            = tostring(var.web_port)
  backend_service       = google_compute_region_backend_service.web.id
  labels                = local.labels
}

# ------------------------------------------------------------------ database

# Cloud SQL keeps a deleted instance name for about a week, so every order gets a name of its own
resource "random_id" "db" {
  byte_length = 3
}

resource "google_sql_database_instance" "db" {
  name                = "${var.name}-db-${random_id.db.hex}"
  region              = var.region
  database_version    = var.db_version
  deletion_protection = false

  settings {
    edition           = "ENTERPRISE"
    tier              = var.db_tier
    availability_type = var.db_availability
    disk_type         = var.db_disk_type
    disk_size         = var.db_disk_size_gb
    disk_autoresize   = false
    user_labels       = local.labels

    ip_configuration {
      ipv4_enabled = true
      ssl_mode     = "ENCRYPTED_ONLY"
    }

    backup_configuration {
      enabled = var.db_backups
    }
  }
}

resource "google_sql_database" "app" {
  name     = var.db_name
  instance = google_sql_database_instance.db.name
}
