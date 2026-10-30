terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source = "hashicorp/google"
      # default_labels needs provider 5.0 or later
      version = ">= 6.0, < 8.0"
    }
  }
}

# No labels and no tags variable in this template: OneCloudify adds its tags as default_labels to this provider block
# at run time (an override file on the MID Server), and the google provider puts them on every resource that takes
# labels. GOOGLE_CREDENTIALS, GOOGLE_PROJECT and GOOGLE_REGION come from the cloud account, as in the other samples.
provider "google" {
  project = var.project == "" ? null : var.project
  region  = var.region
}
