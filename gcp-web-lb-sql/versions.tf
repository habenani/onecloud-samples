terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.0, < 8.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5"
    }
  }
}

# OneCloudify exports GOOGLE_CREDENTIALS (the service account key built on the MID Server from the Google API credential),
# GOOGLE_PROJECT (the project id of the cloud service account) and GOOGLE_REGION (the region of the order). The google
# provider reads all three from the environment, so nothing is hardcoded here. project and region below win when set.
provider "google" {
  project = var.project == "" ? null : var.project
  region  = var.region
}
