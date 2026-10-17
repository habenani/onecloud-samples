# Azure container instance

Runs one container from a public image in Azure Container Instances, with a public IP address and a DNS name, in a resource group of its own. Pick the image, the CPU cores and the memory when you order; the default image is the Azure hello world web page. Remove deletes the container group and its resource group. Needs an Azure cloud account in OneCloud whose credential is an Azure Service Principal.

## What the requester fills in

| Variable | Control in the catalog | Notes |
|---|---|---|
| `name` | text, mandatory | Container group name and DNS label, 3 to 40 lowercase characters |
| `resource_group_name` | text, mandatory | Created by the template, deleted on Remove |
| `location` | text | Map it to the account region (Variable mappings, value source Region) so it is not asked |
| `image` | text | Default `mcr.microsoft.com/azuredocs/aci-helloworld:latest` |
| `cpu_cores` | select box | 0.5, 1 (default) or 2 |
| `memory_gb` | select box | 0.5, 1, 1.5 (default), 2 or 4 |
| `port` | number | Default 80 |
| `cost_centre` | text | Default `CC-1001` |
| `test_tag` | text | Optional. Puts an `OneCloudTest` tag on every resource for test clean up |
| `tags` | filled by OneCloud | Hide it in the variable mapping |

## Day-2 operations it lights up

| Operation | How |
|---|---|
| Start containers, Stop containers, Restart containers | `az container start`, `stop` and `restart` on the MID Server. A stopped group is not billed; the public IP address can change |
| Update | changes `image`, `cpu_cores` or `memory_gb`; Terraform replaces the container group, so it is unavailable for a minute or two and gets a new IP address |

Checked against the azurerm provider 4.x documentation and the Azure Container Instances documentation on 17 October 2026.
