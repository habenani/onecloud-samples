# Azure AKS basic

Creates a small Azure Kubernetes Service cluster in a resource group of its own: one system node pool of 1 to 3 nodes, the free tier control plane and a system assigned identity. Pick the Kubernetes version and the number of nodes when you order. Remove deletes the cluster, its resource group and the node resource group Azure made for it. Needs an Azure cloud account in OneCloud whose credential is an Azure Service Principal with Contributor on the subscription.

## What the requester fills in

| Variable | Control in the catalog | Notes |
|---|---|---|
| `name` | text, mandatory | Cluster name and DNS prefix, 3 to 40 lowercase characters |
| `resource_group_name` | text, mandatory | Created by the template, deleted on Remove |
| `location` | text | Map it to the account region (Variable mappings, value source Region) so it is not asked |
| `kubernetes_version` | select box | 1.35 (default), 1.36 or 1.37. Azure picks the latest patch of that minor version |
| `node_count` | number | 1 (default) to 3 |
| `node_vm_size` | select box | Standard_D2as_v4 (default) or Standard_D2s_v3, 2 vCPUs each |
| `cost_centre` | text | Default `CC-1001`, put on every resource as the `cost_centre` tag |
| `test_tag` | text | Optional. Puts an `OneCloudTest` tag on every resource for test clean up |
| `tags` | filled by OneCloud | Hide it in the variable mapping |

## Day-2 operations it lights up

| Operation | How |
|---|---|
| Scale node pool | sets `node_count`, Terraform plan and apply |
| Upgrade Kubernetes version | sets `kubernetes_version` for the control plane and the node pool, one minor version at a time |
| Stop cluster, Start cluster | `az aks stop` and `az aks start` on the MID Server. A stopped cluster accepts only Start and Remove |
| Update | changes the order form settings, for example `node_vm_size` (the system pool is rebuilt through a temporary pool) |

## Quota

Every node is a 2 vCPU virtual machine. An upgrade adds one more node while it runs (`max_surge = 1`). A one node cluster therefore needs 4 vCPUs of the Dasv4 family in the region during an upgrade, and scaling to 3 nodes needs 6.

Checked against `az aks get-versions --location uksouth` and the azurerm provider 4.x documentation on 17 October 2026.
