# Azure Kubernetes Service sample for OneCloud.
# One resource group and one AKS cluster with a single system node pool, free tier control plane, system assigned
# identity and the Azure default network (kubenet free, no virtual network of its own). Small on purpose: one node of
# 2 vCPUs is enough for a test cluster.
#
# Day-2 through OneCloud: Scale node pool sets node_count, Upgrade Kubernetes version sets kubernetes_version (the
# control plane and the node pool move together), Stop cluster and Start cluster use az aks stop and az aks start.

locals {
  # Template tags first, OneCloud tags last so the deployment correlation tag always wins.
  tags = merge(
    {
      Name        = var.name
      template    = "azure-aks-basic"
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

resource "azurerm_kubernetes_cluster" "this" {
  name                = var.name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  dns_prefix          = var.name
  kubernetes_version  = var.kubernetes_version
  sku_tier            = "Free"
  tags                = local.tags

  default_node_pool {
    name                 = "system"
    vm_size              = var.node_vm_size
    node_count           = var.node_count
    orchestrator_version = var.kubernetes_version
    os_disk_size_gb      = 30
    # a new size needs a temporary pool while the system pool is rebuilt
    temporary_name_for_rotation = "systemtmp"
    tags                        = local.tags

    upgrade_settings {
      # one extra node while an upgrade replaces the nodes, so a one node cluster needs 2 more vCPUs for that time
      max_surge = "1"
    }
  }

  identity {
    type = "SystemAssigned"
  }
}
