terraform {
  required_version = ">= 1.5"

  required_providers {
    vsphere = {
      source  = "vmware/vsphere"
      version = "~> 2.6"
    }
  }
}

# The vCenter address, user and password come from the environment OneCloudify exports on the runner:
# VSPHERE_SERVER (from the Datacenter URL of the cloud service account), VSPHERE_USER and VSPHERE_PASSWORD (from the
# VMware credential) and VSPHERE_ALLOW_UNVERIFIED_SSL (provider mapping). Nothing is hardcoded here on purpose.
provider "vsphere" {}
