# Azure three tier

Creates a web server and an app server in Azure, each in its own subnet with its own network security group, plus a private storage account for app data, all in a resource group of their own. The web server has a static public IP and accepts the ports you list; the app server has no public IP, takes traffic from the web subnet only and carries managed data disks. Remove deletes the resource group and everything in it. Needs an Azure cloud account in OneCloud whose credential is an Azure Service Principal.

## What the requester fills in

| Variable | Control in the catalog | Notes |
|---|---|---|
| `name` | text, mandatory | Base name, 2 to 20 lowercase characters |
| `resource_group_name` | text, mandatory | Created by the template, deleted on Remove |
| `location` | text | Map it to the account region (Variable mappings, value source Region) so it is not asked |
| `ssh_public_key` | text, mandatory | One OpenSSH public key line |
| `web_vm_size`, `app_vm_size` | select box | Standard_B1s (default), Standard_B1ms or Standard_B2s |
| `web_os_disk_size_gb`, `app_os_disk_size_gb` | number | Default 30, grow only |
| `app_data_disk_sizes_gb` | list | Default one 8 GB disk |
| `ingress_ports` | list | TCP ports of the web tier, default 80 and 443 |
| `ingress_source_cidr` | text | Who may reach those ports, default anywhere |
| `admin_username` | text | Default `azureuser` |
| `address_space`, `web_subnet_prefix`, `app_subnet_prefix` | text | Defaults in `10.70.0.0/16` |
| `test_tag` | text | Optional. Puts an `OneCloudTest` tag on every resource for test clean up |
| `tags` | filled by OneCloud | Hide it in the variable mapping |

## Day-2 operations it lights up

Variables named `<tier>_<setting>` belong to the server whose Terraform name is `<tier>` (`azurerm_linux_virtual_machine.web` and `.app`), so an operation run on one server changes only that server.

| Operation | Variable |
|---|---|
| Resize | `web_vm_size`, `app_vm_size` |
| Expand disk | `web_os_disk_size_gb`, `app_os_disk_size_gb` |
| Add a data disk | `app_data_disk_sizes_gb` (app server) |
| Open a port, Close a port | `ingress_ports` (web tier) |
| Start, Stop, Restart | either server, through the Azure CLI |

A database tier (Azure Database for PostgreSQL flexible server, Burstable B1ms) is in `main.tf` and `variables.tf` as comments, with `db_sku_name` and `db_storage_gb` for Change database size and Grow database storage. Uncomment both parts to use it.

## Outputs

`resource_group`, `web_public_ip`, `web_private_ip`, `app_private_ip`, `web_vm_id`, `app_vm_id`, `storage_account_name` and `open_ports`.

## Costs

Two Standard_B1s servers, two 30 GB and one 8 GB Standard HDD disks, one Standard public IP and an LRS storage account. Stop deallocates a server, which stops the compute charge; disks and the public IP are still billed.

## Provider version

Written for `hashicorp/azurerm` 4.x. The storage account refuses public network access, so the provider runs with `features { storage { data_plane_available = false } }`.

## Try it locally

```
export ARM_CLIENT_ID=... ARM_CLIENT_SECRET=... ARM_TENANT_ID=... ARM_SUBSCRIPTION_ID=...
terraform init
terraform plan -var name=demo3t -var resource_group_name=rg-demo3t -var "ssh_public_key=$(cat ~/.ssh/id_ed25519.pub)"
```
