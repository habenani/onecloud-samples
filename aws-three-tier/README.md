# AWS three tier

Creates a web server and an app server in AWS in a VPC of their own: the web server sits in a public subnet behind an internet gateway and accepts the ports you list, the app server sits in a private subnet with no way out to the internet and takes traffic on its app port from the web tier only. The app server carries EBS data volumes, and a private S3 bucket holds app data. There is no NAT gateway, so the network itself costs nothing by the hour. Remove deletes everything, the bucket and its objects included. Needs an AWS cloud account in OneCloud whose identity may build VPCs, instances, volumes, security groups and S3 buckets in the region (cloud-bootstrap/aws-bootstrap.sh gives it exactly that).

## What the requester fills in

| Variable | Control in the catalog | Notes |
|---|---|---|
| `name` | text, mandatory | Base name, 2 to 24 lowercase characters |
| `region` | text | Map it to the account region (Variable mappings, value source Region) so it is not asked |
| `web_instance_type`, `app_instance_type` | select box | t3.micro (default) or t3.small |
| `web_root_volume_size`, `app_root_volume_size` | number | Default 8 GB, grow only |
| `app_data_disk_sizes_gb` | list | Default one 8 GB gp3 volume, up to 4 |
| `ingress_ports` | list | TCP ports of the web tier, default 80 and 443 |
| `ingress_source_cidr` | text | Who may reach those ports, default anywhere |
| `app_port` | number | Default 8080 |
| `ssh_public_key` | text | Optional; empty means no key pair |
| `vpc_cidr`, `public_subnet_cidr`, `private_subnet_cidr` | text | Defaults in `10.80.0.0/16` |
| `cost_centre` | text | Default `CC-1001`, put on every resource as the `cost_centre` tag |
| `test_tag` | text | Optional. Puts an `OneCloudTest` tag on every resource for test clean up |
| `tags` | filled by OneCloud | Hide it in the variable mapping |

## Day-2 operations it lights up

Variables named `<tier>_<setting>` belong to the server whose Terraform name is `<tier>` (`aws_instance.web` and `.app`), so an operation run on one server changes only that server.

| Operation | Variable |
|---|---|
| Resize | `web_instance_type`, `app_instance_type` (AWS stops and starts the server for a new type) |
| Expand disk | `web_root_volume_size`, `app_root_volume_size` (EBS grows in place) |
| Add a data disk | `app_data_disk_sizes_gb` (app server) |
| Open a port, Close a port | `ingress_ports` (web tier, one security group rule per port) |
| Start, Stop, Restart | either server, through the AWS CLI |

## Outputs

`vpc_id`, `web_public_ip`, `web_private_ip`, `app_private_ip`, `web_instance_id`, `app_instance_id`, `data_bucket` and `open_ports`.

## Costs

Two t3.micro servers (free tier eligible on accounts that still have it), two 8 GB and one 8 GB gp3 volumes, one public IPv4 address on the web server (billed by the hour) and an empty S3 bucket. Stop ends the compute charge; volumes and the public address are still billed.

## Provider version

Written for `hashicorp/aws` 5.x and 6.x. Security group rules are separate `aws_vpc_security_group_ingress_rule` resources, so opening or closing one port leaves the others alone.

## Try it locally

```
export AWS_ACCESS_KEY_ID=... AWS_SECRET_ACCESS_KEY=...
terraform init
terraform plan -var name=demo3t -var region=eu-west-2
```
