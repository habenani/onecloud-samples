# OneCloudify sample templates

Sample Terraform templates for Intelibliss OneCloudify. Each folder is one template and becomes one catalog item
in Employee Center when the folder is scanned by a OneCloudify template source.

| Folder | What it provisions | Credentials needed |
|---|---|---|
| `random-pet` | A random name and a local marker file. Uses only the `random` and `local` providers, so it runs anywhere. Good for a first end to end test. | none |
| `aws-vpc` | A VPC with public and private subnets using the community VPC module. | AWS |
| `azure-resource-group` | A resource group and a storage account. | Azure |
| `azure-vm` | An Ubuntu 22.04 LTS virtual machine with its own virtual network, subnet, network security group, optional public IP and network interface, in a new or existing resource group. The end to end Azure walkthrough in the OneCloudify repository (docs/guides/azure-vm-end-to-end.md) uses it. | Azure |
| `azure-three-tier` | A web server with a public IP and an app server without one, each in its own subnet and network security group, managed data disks on the app server and a private storage account, in a resource group of their own. Used by the OneCloudify Azure day-2 test. | Azure |
| `azure-aks-basic` | A small AKS cluster with one system node pool (1 to 3 nodes), free tier control plane, Kubernetes version picked from a list. Used by the OneCloudify container test (scale, upgrade, stop and start). | Azure |
| `azure-container-instance` | One container from a public image in Azure Container Instances with a public IP address and DNS name. Used by the OneCloudify container test (restart, stop and start, change image or CPU). | Azure |
| `aws-three-tier` | A VPC of its own with a public web server and a private app server (t3.micro), security groups per tier, EBS data volumes on the app server and a private S3 bucket. No NAT gateway. | AWS |
| `azure-discovery-sampler` | One of each Azure type OneCloudify records in the CMDB (VM, disk, NIC, public IP, NSG, VNet, subnet, AKS, container group, Azure SQL, load balancer, one unmapped type). Order it to check how your instance records and discovers each type, then remove it. | Azure |
| `aws-discovery-sampler` | One of each AWS type OneCloudify records in the CMDB (EC2, EBS, VPC, subnets, security group, internal ALB, RDS PostgreSQL, unmapped types). Order it to check how your instance records and discovers each type, then remove it. | AWS |
| `aws-eks-basic` | An EKS cluster with one managed node group and its two IAM roles (path /onecloudify/) in the default VPC. Planned by OneCloudify, not applied: needs a key with EKS and IAM rights. | AWS |
| `aws-ecs-fargate` | An ECS cluster, task definition, security group and Fargate service from a public image in the default VPC. Planned by OneCloudify, not applied. | AWS |
| `gcp-three-tier` | A Google Cloud VPC network of its own with a web server (external IP address, one firewall rule per port) and an app server without an external address (e2-micro), persistent data disks on the app server and a private Cloud Storage bucket. No Cloud NAT. | Google Cloud |
| `gcp-gke-basic` | A zonal GKE Standard cluster with one managed node pool (1 to 3 nodes), Kubernetes version from a list, no release channel. Used for Scale node pool and Upgrade Kubernetes version. | Google Cloud |
| `oci-three-tier` | An Oracle Cloud VCN of its own with a public web server and a private app server on flexible shapes (Always Free Arm choice), a network security group rule per port, block volumes on the app server and a private Object Storage bucket. No NAT gateway. | Oracle Cloud |
| `oci-oke-basic` | An OKE basic cluster (no cluster fee) with one managed node pool (1 to 3 nodes, flexible shape) in a VCN of its own. Used for Scale node pool and Upgrade Kubernetes version. | Oracle Cloud |

Conventions OneCloudify reads:

- `variable` blocks become catalog variables. `description` is the help text, `sensitive = true` becomes a masked
  variable, `validation { condition = contains([...], var.x) }` becomes a select box.
- A variable named `tags` of type `map(string)` receives the standard OneCloudify tags.
- `output` values are shown to the requester after apply unless marked sensitive.
- `README.md` first paragraph becomes the catalog item short description.

## Complex templates (`complex/`)

Templates that exercise every variable type, attribute and file layout OneCloudify reads. Point a template source at the path `complex` to scan them.

| Folder | What it provisions | Credentials needed |
|---|---|---|
| `complex/aws-landing-zone` | A VPC with three subnets (local module), a network ACL, a security group and a private S3 bucket with versioning, a lifecycle rule and one object listing every value Terraform received. 45 variables over four files, `terraform.tfvars`, `*.auto.tfvars`, `*.auto.tfvars.json`, a registry module, sensitive and ephemeral variables. Free while idle. | AWS |
| `complex/azure-network-json` | A resource group, virtual network, subnets and a network security group, written only in Terraform JSON syntax, with `terraform.tfvars.json`. Free. | Azure |
| `complex/aws-mixed-bucket` | A private S3 bucket with an expiry rule, mixing `.tf` and `.tf.json` files. Free while empty. | AWS |
