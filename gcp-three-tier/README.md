# Google Cloud three tier

Creates a web server and an app server in Google Cloud in a VPC network of their own: the web server sits in the web subnet with an external IP address and accepts the ports you list (one firewall rule per port), the app server sits in the app subnet without an external address and takes traffic on its app port from the web server only. The app server carries persistent data disks, and a private Cloud Storage bucket holds app data. There is no Cloud NAT and no load balancer, so the network itself is not billed by the hour. Remove deletes everything, the bucket and its objects included. Needs a Google Cloud cloud account in OneCloud whose service account may create networks, firewall rules, instances, disks, addresses and buckets in the project (cloud-bootstrap/gcp-bootstrap.sh gives it those roles).

## What the requester fills in

| Variable | Control in the catalog | Notes |
|---|---|---|
| `name` | text, mandatory | Base name, 2 to 24 lowercase characters, starting with a letter |
| `region` | text | Map it to the account region (Variable mappings, value source Region) so it is not asked |
| `zone_suffix` | select box | Zone letter inside the region, default `a` |
| `project` | text | Leave empty: the project of the cloud account (GOOGLE_PROJECT) is used. Hide it in the variable mapping |
| `web_machine_type`, `app_machine_type` | select box | e2-micro (default) or e2-small |
| `web_boot_disk_size`, `app_boot_disk_size` | number | Default 10 GB, grow only |
| `app_data_disk_sizes_gb` | list | Default one 10 GB balanced persistent disk, up to 4 |
| `ingress_ports` | list | TCP ports of the web tier, default 80 and 443 |
| `ingress_source_cidr` | text | Who may reach those ports, default anywhere |
| `app_port` | number | Default 8080 |
| `ssh_public_key` | text | Optional; empty means no key in the instance metadata (use IAP or OS Login) |
| `web_subnet_cidr`, `app_subnet_cidr` | text | Defaults in `10.90.0.0/16` |
| `cost_centre` | text | Default `CC-1001`, put on every resource as the `cost_centre` label |
| `test_tag` | text | Optional. Puts an `onecloudtest` label on every resource for test clean up |
| `tags` | filled by OneCloud | Hide it in the variable mapping. Applied as labels in lower case, other characters become underscores |

## Day-2 operations it lights up

Variables named `<tier>_<setting>` belong to the server whose Terraform name is `<tier>` (`google_compute_instance.web` and `.app`), so an operation run on one server changes only that server.

| Operation | Variable |
|---|---|
| Resize | `web_machine_type`, `app_machine_type` (Terraform stops and starts the server for a new machine type) |
| Expand disk | `web_boot_disk_size`, `app_boot_disk_size` (persistent disks grow in place) |
| Add a data disk | `app_data_disk_sizes_gb` (app server) |
| Open a port, Close a port | `ingress_ports` (web tier, one firewall rule per port) |
| Start, Stop, Restart | either server, through gcloud on the MID Server |

## Outputs

`network`, `web_public_ip`, `web_private_ip`, `app_private_ip`, `web_instance_id`, `app_instance_id`, `data_bucket`, `open_ports` and `web_url`.

## Costs

Two e2-micro servers, two 10 GB balanced boot disks and one 10 GB balanced data disk, one static external IPv4 address (billed by the hour while it exists, also when the server is stopped) and an empty Cloud Storage bucket. The Google Cloud free tier covers one e2-micro and 30 GB of standard persistent disk a month only in us-west1, us-central1 and us-east1. Stop ends the compute charge; disks and the address are still billed.

## Provider version

Written for `hashicorp/google` 6.x and 7.x (validated with 7.x and `hashicorp/random` 3.x on Terraform 1.11). Each web port is a separate `google_compute_firewall`, so opening or closing one port leaves the others alone. The data disks use `google_compute_attached_disk`, so the app instance ignores changes to `attached_disk`.

## Try it locally

```
export GOOGLE_CREDENTIALS="$(cat key.json)" GOOGLE_PROJECT=shop-dev-123456
terraform init
terraform plan -var name=demo3t -var region=europe-west2
```
