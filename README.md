# OneCloud sample templates

Sample Terraform templates for Intelibliss OneCloud. Each folder is one template and becomes one catalog item
in Employee Center when the folder is scanned by a OneCloud template source.

| Folder | What it provisions | Credentials needed |
|---|---|---|
| `random-pet` | A random name and a local marker file. Uses only the `random` and `local` providers, so it runs anywhere. Good for a first end to end test. | none |
| `aws-vpc` | A VPC with public and private subnets using the community VPC module. | AWS |
| `azure-resource-group` | A resource group and a storage account. | Azure |
| `azure-vm` | An Ubuntu 22.04 LTS virtual machine with its own virtual network, subnet, network security group, optional public IP and network interface, in a new or existing resource group. The end to end Azure walkthrough in the OneCloud repository (docs/guides/azure-vm-end-to-end.md) uses it. | Azure |
| `azure-three-tier` | A web server with a public IP and an app server without one, each in its own subnet and network security group, managed data disks on the app server and a private storage account, in a resource group of their own. Used by the OneCloud Azure day-2 test. | Azure |
| `azure-aks-basic` | A small AKS cluster with one system node pool (1 to 3 nodes), free tier control plane, Kubernetes version picked from a list. Used by the OneCloud container test (scale, upgrade, stop and start). | Azure |
| `azure-container-instance` | One container from a public image in Azure Container Instances with a public IP address and DNS name. Used by the OneCloud container test (restart, stop and start, change image or CPU). | Azure |
| `aws-eks-basic` | An EKS cluster with one managed node group and its two IAM roles in the default VPC. Planned by OneCloud, not applied: needs a key with EKS and IAM rights. | AWS |
| `aws-ecs-fargate` | An ECS cluster, task definition, security group and Fargate service from a public image in the default VPC. Planned by OneCloud, not applied. | AWS |

Conventions OneCloud reads:

- `variable` blocks become catalog variables. `description` is the help text, `sensitive = true` becomes a masked
  variable, `validation { condition = contains([...], var.x) }` becomes a select box.
- A variable named `tags` of type `map(string)` receives the standard OneCloud tags.
- `output` values are shown to the requester after apply unless marked sensitive.
- `README.md` first paragraph becomes the catalog item short description.
