# Google Kubernetes Engine basic sample for OneCloud.
# A zonal GKE Standard cluster in the project's default network with one separately managed node pool of 1 to 3
# nodes. The cluster has no release channel, so the Kubernetes version stays where the order put it until someone
# runs Upgrade Kubernetes version. deletion_protection is off so Remove can delete the cluster.
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
data "google_container_engine_versions" "this" {
  location       = local.zone
  version_prefix = "${var.kubernetes_version}."
}

resource "google_container_cluster" "this" {
  name                = var.name
  location            = local.zone
  deletion_protection = false
  min_master_version  = data.google_container_engine_versions.this.latest_master_version
  resource_labels     = local.labels

  # the default pool is removed straight away; the managed pool below holds the nodes
  remove_default_node_pool = true
  initial_node_count       = 1

  release_channel {
    channel = "UNSPECIFIED"
  }

  ip_allocation_policy {}
}

resource "google_container_node_pool" "this" {
  name       = "${var.name}-pool"
  location   = local.zone
  cluster    = google_container_cluster.this.name
  node_count = var.node_count
  version    = data.google_container_engine_versions.this.latest_node_version

  management {
    auto_repair  = true
    auto_upgrade = false
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
