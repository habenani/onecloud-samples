# Google Kubernetes Engine basic sample for OneCloud.
# A zonal GKE Standard cluster in the project's default network with one separately managed node pool of 1 to 3
# nodes, enrolled in a release channel (REGULAR by default). Google refuses new clusters without a release channel for
# new customers ("not enrolling clusters in a release channel is now only allowed for existing customers"), so the
# channel is required. The order picks the Kubernetes minor version; GKE takes the newest patch of that minor the
# channel offers. Within a channel Google upgrades the control plane and nodes on its own schedule as well.
# deletion_protection is off so Remove can delete the cluster.
#
# Day-2 through OneCloud: Scale node pool sets node_count, Upgrade Kubernetes version sets kubernetes_version (control
# plane first, then the node pool), Update changes the other order form settings.

locals {
  zone = "${var.region}-${var.zone_suffix}"
  raw_labels = merge(
    {
      name        = var.name
      template    = "gcp-gke-basic"
      cost_centre = var.cost_centre
    },
    var.test_tag == "" ? {} : { onecloudtest = var.test_tag },
    var.tags,
  )
  labels = {
    for k, v in local.raw_labels :
    substr(lower(replace(k, "/[^A-Za-z0-9_-]/", "_")), 0, 63) => substr(lower(replace(v, "/[^A-Za-z0-9_-]/", "_")), 0, 63)
  }
}

# the newest patch GKE offers in the zone for the chosen minor version
resource "google_container_cluster" "this" {
  name                = var.name
  location            = local.zone
  deletion_protection = false
  # a minor version ("1.35"): GKE resolves it to the newest patch the release channel offers for that minor
  min_master_version = var.kubernetes_version
  resource_labels    = local.labels

  # the default pool is removed straight away; the managed pool below holds the nodes
  remove_default_node_pool = true
  initial_node_count       = 1

  release_channel {
    channel = var.release_channel
  }

  ip_allocation_policy {}
}

resource "google_container_node_pool" "this" {
  name       = "${var.name}-pool"
  location   = local.zone
  cluster    = google_container_cluster.this.name
  node_count = var.node_count
  # the nodes follow the control plane: Upgrade Kubernetes version upgrades the control plane first, then this pool
  version = google_container_cluster.this.master_version

  management {
    auto_repair  = true
    auto_upgrade = true # required by GKE for node pools of a cluster in a release channel
  }

  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
  }

  node_config {
    machine_type = var.node_machine_type
    disk_size_gb = var.node_disk_size_gb
    disk_type    = "pd-balanced"
    labels       = local.labels
    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]

    shielded_instance_config {
      enable_secure_boot = true
    }
  }
}
