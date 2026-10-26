# Linux web server

Amazon EC2 instance in a new VPC with a public subnet, an internet gateway and a security group for SSH (22) and HTTP (80, 8080). Outputs the public IP address.

Based on the HashiCorp tutorial template hashicorp-education/learn-terraform-provisioning (folder `instances`, MPL-2.0). OneCloudify's copy asks for the size instead of fixing it to t2.micro, which several regions (eu-north-1 among them) don't offer, and uses the current Amazon Linux 2023 image instead of a placeholder AMI id.

## What the requester fills in

| Variable | Control in the catalog | Notes |
|---|---|---|
| `instance_type` | select box | `t3.micro` (default), `t3.small` or `t3.medium`, current generation sizes every commercial region offers |
| `region` | filled by OneCloudify | From the region picked on the order |
| `cidr_vpc`, `cidr_subnet` | text | Address ranges of the new VPC and its public subnet |
| `environment_tag` | text | Value of the `Environment` tag |
| `tags` | filled by OneCloudify | Deployment tags, including `onecloud_deployment` |

## Outputs

| Output | What it is |
|---|---|
| `public_ip` | Public IP address of the server |
