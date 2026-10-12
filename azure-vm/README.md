# Azure Linux virtual machine

Creates an Ubuntu 22.04 LTS virtual machine in Azure with its own virtual network, subnet, network security group (SSH from one CIDR block), optional static public IP and network interface. The resource group is created or reused. Needs an Azure cloud account in OneCloud whose credential alias points at an Azure Service Principal credential.

## What the requester fills in

| Variable | Control in the catalog | Notes |
|---|---|---|
| `name` | text, mandatory | Base name for everything, 2 to 32 lowercase characters |
| `resource_group_name` | text, mandatory | Created unless `create_resource_group` is unticked |
| `create_resource_group` | checkbox | Default on |
| `location` | text | Map it to the account region in OneCloud (Variable mappings, value source Region) so it is not asked |
| `ssh_source_cidr` | text, mandatory | Who may SSH in |
| `ssh_public_key` | text, mandatory | One OpenSSH public key line |
| `create_public_ip` | checkbox | Default on |
| `vm_size` | text | Default `Standard_B1s` |
| `os_disk_type` | select box | From the `contains([...])` validation |
| `admin_username` | text | Default `azureuser` |
| `address_space`, `subnet_prefix` | text | Defaults in `10.60.0.0/16` |
| `tags` | filled by OneCloud | Hide it in the variable mapping |

## Outputs

`vm_id`, `private_ip`, `public_ip` (empty without a public IP) and `resource_group`.

## Resource types OneCloud maps to the CMDB

`azurerm_resource_group`, `azurerm_virtual_network`, `azurerm_subnet`, `azurerm_network_security_group`, `azurerm_public_ip`, `azurerm_network_interface` and `azurerm_linux_virtual_machine` all have rows in the OneCloud resource type map, so the post apply step writes a CI for each and targeted discovery runs the matching Azure pattern. The security group association has no CI and shows as an unmapped type, which is expected.

## Provider version

Written for `hashicorp/azurerm` 4.x. The provider reads `ARM_SUBSCRIPTION_ID` from the environment (4.x requires a subscription id), which OneCloud exports from the cloud account.

## Try it locally

```
export ARM_CLIENT_ID=... ARM_CLIENT_SECRET=... ARM_TENANT_ID=... ARM_SUBSCRIPTION_ID=...
terraform init
terraform plan -var name=demo-vm -var resource_group_name=rg-demo-vm -var ssh_source_cidr=203.0.113.0/24 -var "ssh_public_key=$(cat ~/.ssh/id_ed25519.pub)"
```
