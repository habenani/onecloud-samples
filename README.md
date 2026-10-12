# OneCloud sample templates

Sample Terraform templates for Intelibliss OneCloud. Each folder is one template and becomes one catalog item
in Employee Center when the folder is scanned by a OneCloud template source.

| Folder | What it provisions | Credentials needed |
|---|---|---|
| `random-pet` | A random name and a local marker file. Uses only the `random` and `local` providers, so it runs anywhere. Good for a first end to end test. | none |
| `aws-vpc` | A VPC with public and private subnets using the community VPC module. | AWS |
| `azure-resource-group` | A resource group and a storage account. | Azure |
| `azure-vm` | An Ubuntu 22.04 LTS virtual machine with its own virtual network, subnet, network security group, optional public IP and network interface, in a new or existing resource group. The end to end Azure walkthrough in the OneCloud repository (docs/guides/azure-vm-end-to-end.md) uses it. | Azure |

Conventions OneCloud reads:

- `variable` blocks become catalog variables. `description` is the help text, `sensitive = true` becomes a masked
  variable, `validation { condition = contains([...], var.x) }` becomes a select box.
- A variable named `tags` of type `map(string)` receives the standard OneCloud tags.
- `output` values are shown to the requester after apply unless marked sensitive.
- `README.md` first paragraph becomes the catalog item short description.
