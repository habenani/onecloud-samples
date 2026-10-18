terraform {
  required_version = ">= 1.5"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 6.0, < 10.0"
    }
  }
}

# OneCloud exports TF_VAR_tenancy_ocid, TF_VAR_user_ocid, TF_VAR_fingerprint, TF_VAR_private_key (and
# TF_VAR_private_key_password when the key has one) from the Oracle API credential, TF_VAR_region from the region of
# the order and TF_VAR_compartment_ocid from the cloud account. The oci provider reads its own TF_VAR_ values straight
# from the environment (checked with provider 9.10: an empty provider block signs in with them), so the credential is
# never a template variable and never a question on the order form. Only the compartment is a variable here.
provider "oci" {
  region = var.region
}
