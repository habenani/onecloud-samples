terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

# Authentication and the subscription come from the environment OneCloud exports on the runner:
# ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID (from the Azure Service Principal credential) and
# ARM_SUBSCRIPTION_ID (from the OneCloud cloud account). Nothing is hardcoded here on purpose.
provider "azurerm" {
  features {
    storage {
      # The storage account below refuses public network access, so the runner cannot reach its data plane.
      # The template uses no queue_properties or static_website blocks, so the provider can skip those calls.
      data_plane_available = false
    }
    resource_group {
      # Remove fails rather than delete something this template did not create.
      prevent_deletion_if_contains_resources = true
    }
  }
}
