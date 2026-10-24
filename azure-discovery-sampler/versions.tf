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

# Authentication and the subscription come from the environment OneCloudify exports on the runner:
# ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID (from the Azure Service Principal credential) and
# ARM_SUBSCRIPTION_ID (from the OneCloudify cloud account). Nothing is hardcoded here on purpose.
provider "azurerm" {
  features {}
}
