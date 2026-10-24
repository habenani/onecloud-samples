# Google Cloud GKE basic

Creates a small zonal Google Kubernetes Engine Standard cluster in the project's default network with one separately managed node pool of 1 to 3 nodes. Pick the Kubernetes version, the number of nodes and the machine type when you order. The cluster is enrolled in a release channel (REGULAR unless you change `release_channel`), because Google no longer lets new customers create clusters without one. Google may also upgrade the cluster within the channel on its own schedule; Upgrade Kubernetes version moves it to the next minor version when you choose. Remove deletes the cluster and its nodes (deletion protection is off). Needs a Google Cloud cloud account in OneCloudify whose service account has Kubernetes Engine Admin and Service Account User in the project, and the Kubernetes Engine API enabled.

## What the requester fills in

| Variable | Control in the catalog | Notes |
|---|---|---|
| `name` | text, mandatory | Cluster name, 3 to 30 lowercase characters |
| `region` | text | Map it to the account region (Variable mappings, value source Region) so it is not asked |
| `zone_suffix` | select box | Zone letter of the zonal cluster, default `a` |
| `project` | text | Leave empty: the project of the cloud account (GOOGLE_PROJECT) is used. Hide it in the variable mapping |
| `kubernetes_version` | select box | 1.34 (default), 1.35 or 1.36. GKE picks the newest patch the release channel offers |
| `release_channel` | select box | REGULAR (default), STABLE, RAPID or EXTENDED |
| `node_count` | number | 1 (default) to 3 |
| `node_machine_type` | select box | e2-medium (default) or e2-standard-2 |
| `node_disk_size_gb` | number | Default 30 GB per node |
| `cost_centre` | text | Default `CC-1001`, put on the cluster and nodes as the `cost_centre` label |
| `test_tag` | text | Optional. Puts an `onecloudtest` label on every resource for test clean up |
| `tags` | filled by OneCloudify | Hide it in the variable mapping. Applied as labels in lower case |

## Day-2 operations it lights up

| Operation | How |
|---|---|
| Scale node pool | sets `node_count`, Terraform plan and apply |
| Upgrade Kubernetes version | sets `kubernetes_version`: the control plane moves to the newest patch of that minor version in the channel; GKE then upgrades the node pool to match on its own (node auto-upgrade, one surge node at a time). One minor version at a time |
| Update | changes the order form settings, for example `node_machine_type` (GKE replaces the nodes) |

GKE has no stop for a cluster: scaling to fewer nodes is the way to cut cost, and Remove deletes it.

## Outputs

`cluster_name`, `location`, `api_server`, `kubernetes_version`, `node_count` and `connect_command`.

## Costs

The cluster management fee per cluster hour (one zonal cluster per billing account is covered by the GKE free tier credit), the nodes as Compute Engine instances and their balanced persistent disks. An upgrade adds one more node while it runs (`max_surge = 1`).

## Provider version

Written for `hashicorp/google` 6.x and 7.x (validated with 7.x on Terraform 1.11). The version list is a starting point: check `gcloud container get-server-config --zone <zone>` (channels, validVersions of your channel) and change the validation list to the minor versions your channel offers.

## Try it locally

```
export GOOGLE_CREDENTIALS="$(cat key.json)" GOOGLE_PROJECT=shop-dev-123456
terraform init
terraform plan -var name=demo-gke -var region=europe-west2
```
