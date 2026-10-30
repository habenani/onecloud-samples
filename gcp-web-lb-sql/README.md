# Google Cloud web servers with load balancer and Cloud SQL

Creates web servers in Google Cloud behind a regional external network load balancer, in a VPC network of their own: the servers have no external IP addresses, Cloud NAT lets them reach the internet for updates, and a Cloud SQL database (PostgreSQL or MySQL, Enterprise edition) holds the app data, reachable only over encrypted connections through the Cloud SQL Auth Proxy. Remove deletes everything, the database included. Needs a Google Cloud cloud account in OneCloudify whose service account may create networks, firewall rules, routers, instances, load balancers and Cloud SQL instances in the project: cloud-bootstrap/gcp-bootstrap.sh gives it compute and storage roles; add `roles/cloudsql.admin` and enable `sqladmin.googleapis.com` for the database.

## What the requester fills in

| Variable | Control in the catalog | Notes |
|---|---|---|
| `name` | text, mandatory | Base name, 2 to 20 lowercase characters, starting with a letter |
| `region` | text | Map it to the account region (Variable mappings, value source Region) so it is not asked |
| `zone_suffix` | select box | Zone letter inside the region for the web servers, default `a` |
| `project` | text | Leave empty: the project of the cloud account (GOOGLE_PROJECT) is used. Hide it in the variable mapping |
| `web_server_count` | number | 1 to 4 web servers, default 2 |
| `web_machine_type` | select box | e2-micro, e2-small (default), e2-medium or n2-standard-2 |
| `web_boot_disk_size` | number | Default 10 GB balanced persistent disk per server, grow only |
| `web_port` | number | Port of the load balancer and nginx on the servers, default 80 |
| `ingress_source_cidr` | text | Who may reach the load balancer, default anywhere |
| `db_version` | select box | POSTGRES_16 (default), POSTGRES_15 or MYSQL_8_0 |
| `db_tier` | select box | db-f1-micro, db-g1-small (shared core) or db-custom-1-3840 (default), db-custom-2-7680, db-custom-4-15360 |
| `db_availability` | select box | ZONAL (default) or REGIONAL (standby in a second zone) |
| `db_disk_type`, `db_disk_size_gb` | select box, number | PD_SSD (default) or PD_HDD, 10 to 500 GB |
| `db_backups` | check box | Daily automated backups, default on |
| `db_name` | text | Application database, default `app` |
| `cost_centre` | text | Default `CC-1001`, put on every resource as the `cost_centre` label |
| `test_tag` | text | Optional. Puts an `onecloudtest` label on every resource for test clean up |
| `tags` | filled by OneCloudify | Hide it in the variable mapping. Applied as labels in lower case, other characters become underscores |

## Day-2 operations it lights up

| Operation | Variable |
|---|---|
| Resize | `web_machine_type` (every web server; Terraform stops and starts each one) |
| Start, Stop, Restart | a web server, through gcloud on the MID Server |

## Outputs

`network`, `load_balancer_ip`, `web_url`, `web_private_ips`, `web_instance_ids`, `nat_name`, `db_connection_name` and `db_public_ip`.

## Costs

The order form estimate prices each part: the web servers (vCPU and memory hours) and their boot disks, the load balancer forwarding rule (the first five rules of a region share one charge, data processed comes on top), Cloud NAT (gateway hours per VM and the NAT IP address) and the Cloud SQL instance (tier, high availability doubles it, storage per GB). Backups, data processing and network egress are billed on top by usage. Stop ends the compute charge of a web server only; the load balancer, NAT and database keep running.

## Provider version

Written for `hashicorp/google` 6.x and 7.x (validated with 7.x and `hashicorp/random` 3.x on Terraform 1.11). The Cloud SQL instance sets `edition = "ENTERPRISE"` (PostgreSQL 16 would otherwise be created as Enterprise Plus) and `deletion_protection = false` so Remove can delete it. Cloud SQL keeps a deleted instance name for about a week, so the instance name carries a random suffix.

## Try it locally

```
export GOOGLE_CREDENTIALS="$(cat key.json)" GOOGLE_PROJECT=shop-dev-123456
terraform init
terraform plan -var name=shop-web -var region=europe-west2
```
