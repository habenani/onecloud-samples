# Google Cloud server with provider labels

Creates one Debian 12 server in Google Cloud in a VPC network of its own, without an external IP address (sign in through IAP). The template sets no labels and has no `tags` variable on purpose: OneCloudify adds the deployment tags to the google provider block as `default_labels` at run time, so the server still carries `onecloud_deployment` and the other standard labels. Use it to see how a template written outside OneCloudify gets labelled. Needs a Google Cloud cloud account in OneCloudify whose service account may create networks, firewall rules and instances (cloud-bootstrap/gcp-bootstrap.sh).

## What the requester fills in

| Variable | Control in the catalog | Notes |
|---|---|---|
| `name` | text, mandatory | Name of the server, 2 to 30 lowercase characters, starting with a letter |
| `region` | text | Map it to the account region (Variable mappings, value source Region) so it is not asked |
| `zone_suffix` | select box | Zone letter inside the region, default `a` |
| `project` | text | Leave empty: the project of the cloud account is used. Hide it in the variable mapping |
| `machine_type` | select box | e2-micro (default, Always Free in us-west1, us-central1 and us-east1), e2-small or e2-medium |
| `boot_disk_size` | number | Default 10 GB standard persistent disk, grow only |
| `subnet_cidr` | text | Default `10.92.1.0/24` |

## How the labels get there

OneCloudify sees that the template version has no `tags` variable and writes `onecloud_tags_override.tf` next to the template on the MID Server before the plan. That override file adds `default_labels` to `provider "google"`, with keys and values in the form Google accepts (lower case, at most 63 characters). Labels a resource sets itself win over the provider defaults. A template that pins the google provider below 5.0 is left alone, with a note on the run.

## Day-2 operations it lights up

| Operation | Variable |
|---|---|
| Resize | `machine_type` (Terraform stops and starts the server) |
| Expand disk | `boot_disk_size` |
| Start, Stop, Restart | through gcloud on the MID Server |

## Outputs

`instance_id`, `private_ip` and `labels` (the labels Google holds on the server, the provider default labels included).

## Costs

One e2-micro server and a 10 GB standard persistent disk, covered by the Google Cloud free tier in us-west1, us-central1 and us-east1. No external IP address, no load balancer and no NAT, so nothing else is billed by the hour.

## Provider version

Written for `hashicorp/google` 6.x and 7.x (validated with 7.x on Terraform 1.11).

## Try it locally

```
export GOOGLE_CREDENTIALS="$(cat key.json)" GOOGLE_PROJECT=shop-dev-123456
terraform init
terraform plan -var name=shop-app-01 -var region=us-central1
```
