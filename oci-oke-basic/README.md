# Oracle Cloud OKE basic

Creates a small Oracle Container Engine for Kubernetes (OKE) basic cluster in a VCN of its own: a public Kubernetes API endpoint in an endpoint subnet and one managed node pool of 1 to 3 worker nodes on a flexible shape in a node subnet, both behind an internet gateway. Pick the Kubernetes version, the number of nodes and the node shape when you order. Remove deletes the node pool, the cluster and the network. Needs an Oracle Cloud cloud account in OneCloud whose user may manage clusters, instances and networks in the account's compartment (cloud-bootstrap/oci-bootstrap.sh writes that policy).

## What the requester fills in

| Variable | Control in the catalog | Notes |
|---|---|---|
| `name` | text, mandatory | Cluster name, 3 to 30 lowercase characters |
| `region` | text | Map it to the account region (Variable mappings, value source Region) so it is not asked |
| `compartment_ocid` | filled by OneCloud | Hide it in the variable mapping: OneCloud sets TF_VAR_compartment_ocid from the cloud account |
| `kubernetes_version` | select box | 1.33 (default), 1.34 or 1.35. The template picks the newest patch OKE offers |
| `node_count` | number | 1 (default) to 3 |
| `node_shape` | select box | shape:OCPUs:memory GB, default `VM.Standard.E4.Flex:1:8` |
| `vcn_cidr` | text | Default `10.60.0.0/16` |
| `api_source_cidr` | text | Who may reach the Kubernetes API, default anywhere |
| `cost_centre` | text | Default `CC-1001`, put on every resource as the `cost_centre` free form tag |
| `test_tag` | text | Optional. Puts an `OneCloudTest` tag on every resource for test clean up |
| `tags` | filled by OneCloud | Hide it in the variable mapping. Applied as free form tags |

## Day-2 operations it lights up

| Operation | How |
|---|---|
| Scale node pool | sets `node_count`, Terraform plan and apply |
| Upgrade Kubernetes version | sets `kubernetes_version` for the control plane and the node pool, one minor version at a time; existing nodes keep their version until OKE cycles them |
| Update | changes the order form settings, for example `node_shape` |

OKE has no stop for a cluster: scaling to fewer nodes is the way to cut cost, and Remove deletes it.

## Outputs

`cluster_name`, `cluster_id`, `api_server`, `kubernetes_version`, `node_count` and `connect_command`.

## Costs

A basic cluster has no cluster fee. The worker nodes are billed as compute instances (OCPU hours and memory GB hours) with their boot volumes. The network, the internet gateway and the ephemeral public IP addresses cost nothing.

## Provider version

Written for `oracle/oci` 6.x to 9.x (validated with 9.10 on Terraform 1.11). The version list is a starting point: check `oci ce cluster-options get --cluster-option-id all` in your region and change the validation list to the minor versions OKE offers. The credential is not a template variable: the provider reads TF_VAR_tenancy_ocid, TF_VAR_user_ocid, TF_VAR_fingerprint, TF_VAR_private_key and TF_VAR_region from the environment OneCloud sets.

## Try it locally

```
export TF_VAR_tenancy_ocid=ocid1.tenancy.oc1..aaaa TF_VAR_user_ocid=ocid1.user.oc1..aaaa
export TF_VAR_fingerprint=12:34:... TF_VAR_private_key="$(cat oci_api_key.pem)"
export TF_VAR_compartment_ocid=ocid1.compartment.oc1..aaaa
terraform init
terraform plan -var name=demo-oke -var region=uk-london-1
```
