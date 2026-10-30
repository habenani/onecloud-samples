# Google Cloud server without template labels, sample for OneCloudify.
# One Debian 12 server in a VPC network of its own, with no external IP address (sign in through IAP). The template
# sets no labels and has no tags variable on purpose: it shows OneCloudify's provider default labels, the way a
# template written outside OneCloudify (for example a public module) still gets the deployment labels.

resource "google_compute_network" "this" {
  name                    = "${var.name}-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "this" {
  name                     = "${var.name}-subnet"
  ip_cidr_range            = var.subnet_cidr
  region                   = var.region
  network                  = google_compute_network.this.id
  private_ip_google_access = true
}

# SSH from Google's Identity-Aware Proxy range only
resource "google_compute_firewall" "iap_ssh" {
  name          = "${var.name}-iap-ssh"
  network       = google_compute_network.this.name
  description   = "SSH through IAP TCP forwarding"
  direction     = "INGRESS"
  source_ranges = ["35.235.240.0/20"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

resource "google_compute_instance" "server" {
  name         = var.name
  machine_type = var.machine_type
  zone         = "${var.region}-${var.zone_suffix}"

  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = var.boot_disk_size
      type  = "pd-standard"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.this.id
  }

  shielded_instance_config {
    enable_secure_boot = true
  }
}
