# Azure Container Instances sample for OneCloudify.
# One resource group and one Linux container group with a single container from a public image, a public IP address
# and a DNS name. Day-2 through OneCloudify: Start, Stop and Restart containers (az container start, stop and restart),
# and Update for the image, CPU and memory (Terraform recreates the group for those).

locals {
  # Template tags first, OneCloudify tags last so the deployment correlation tag always wins.
  tags = merge(
    {
      Name        = var.name
      template    = "azure-container-instance"
      cost_centre = var.cost_centre
    },
    var.test_tag == "" ? {} : { OneCloudTest = var.test_tag },
    var.tags,
  )
}

resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location
  tags     = local.tags
}

resource "azurerm_container_group" "this" {
  name                = var.name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  os_type             = "Linux"
  ip_address_type     = "Public"
  dns_name_label      = var.name
  restart_policy      = "Always"
  tags                = local.tags

  container {
    name   = "app"
    image  = var.image
    cpu    = var.cpu_cores
    memory = var.memory_gb

    ports {
      port     = var.port
      protocol = "TCP"
    }
  }
}
