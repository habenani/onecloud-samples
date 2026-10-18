variable "project" {
  description = "Google Cloud project id. Leave empty to use the project of the OneCloud cloud account (GOOGLE_PROJECT)."
  type        = string
  default     = ""

  validation {
    condition     = var.project == "" || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project))
    error_message = "project must be empty or a Google Cloud project id (6 to 30 lowercase letters, digits and hyphens)."
  }
}

variable "region" {
  description = "Google Cloud region, for example europe-west2. OneCloud fills it from the region picked on the order."
  type        = string
  default     = "europe-west2"

  validation {
    condition     = can(regex("^[a-z]+-[a-z]+[0-9]{1,2}$", var.region))
    error_message = "region must be a Google Cloud region such as europe-west2."
  }
}

variable "zone_suffix" {
  description = "Zone letter of the zonal cluster inside the region, for example a for europe-west2-a."
  type        = string
  default     = "a"

  validation {
    condition     = contains(["a", "b", "c", "d", "f"], var.zone_suffix)
    error_message = "zone_suffix must be a, b, c, d or f."
  }
}

variable "name" {
  description = "Name of the cluster. Lowercase letters, digits and hyphens, 3 to 30 characters, starting with a letter."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,28}[a-z0-9]$", var.name))
    error_message = "name must be 3 to 30 characters of lowercase letters, digits and hyphens, starting with a letter and not ending with a hyphen."
  }
}

variable "kubernetes_version" {
  description = "Kubernetes minor version of the control plane and the node pool. GKE picks the newest patch it offers for that minor version in the zone. Upgrade one minor version at a time."
  type        = string
  default     = "1.34"

  validation {
    condition     = contains(["1.34", "1.35", "1.36"], var.kubernetes_version)
    error_message = "kubernetes_version must be 1.34, 1.35 or 1.36. Check the versions your zone offers with gcloud container get-server-config and change the list to match."
  }
}

variable "node_count" {
  description = "Number of nodes in the node pool. Each node is one Compute Engine instance of node_machine_type."
  type        = number
  default     = 1

  validation {
    condition     = var.node_count >= 1 && var.node_count <= 3
    error_message = "node_count must be from 1 to 3."
  }
}

variable "node_machine_type" {
  description = "Machine type of each node. e2-medium has 2 shared vCPUs and 4 GB, e2-standard-2 has 2 vCPUs and 8 GB."
  type        = string
  default     = "e2-medium"

  validation {
    condition     = contains(["e2-medium", "e2-standard-2"], var.node_machine_type)
    error_message = "node_machine_type must be e2-medium or e2-standard-2."
  }
}

variable "node_disk_size_gb" {
  description = "Boot disk size of each node in GB."
  type        = number
  default     = 30

  validation {
    condition     = var.node_disk_size_gb >= 20 && var.node_disk_size_gb <= 100
    error_message = "node_disk_size_gb must be from 20 to 100."
  }
}

variable "test_tag" {
  description = "Value of the onecloudtest label put on every resource, so a test can find and remove what it made. Leave empty outside tests."
  type        = string
  default     = ""

  validation {
    condition     = can(regex("^[a-z0-9_-]{0,63}$", var.test_tag))
    error_message = "test_tag must be up to 63 lowercase letters, digits, underscores or hyphens (a Google label value)."
  }
}

variable "cost_centre" {
  description = "Cost centre the cluster is charged to, put on every resource as the cost_centre label (in lower case, as Google labels require)."
  type        = string
  default     = "CC-1001"

  validation {
    condition     = can(regex("^[A-Za-z0-9-]{1,20}$", var.cost_centre))
    error_message = "cost_centre must be 1 to 20 letters, digits or hyphens."
  }
}

variable "tags" {
  description = "Tags applied to the cluster and the nodes as Google labels. OneCloud passes the deployment tags here, including the onecloud_deployment correlation tag. Keys and values are put in lower case and other characters become underscores."
  type        = map(string)
  default     = {}
}
