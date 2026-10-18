# Oracle Cloud three tier

Creates a web server and an app server in Oracle Cloud Infrastructure in a VCN of their own: the web server sits in a public subnet behind an internet gateway with a public IP address and accepts the ports you list (one network security group rule per port), the app server sits in a private subnet that allows no public IP addresses and takes traffic on its app port from the web tier only. Both run Oracle Linux 9 on flexible shapes, the app server carries block volumes, and a private Object Storage bucket holds app data. There is no NAT gateway. Remove deletes everything; Object Storage only deletes an empty bucket, so empty it first if the app wrote to it. Needs an Oracle Cloud cloud account in OneCloud whose user may manage networks, instances, volumes and buckets in the account's compartment (cloud-bootstrap/oci-bootstrap.sh writes that policy).

## What the requester fills in

| Variable | Control in the catalog | Notes |
|---|---|---|
| `name` | text, mandatory | Base name, 2 to 24 lowercase characters, starting with a letter |
| `region` | text | Map it to the account region (Variable mappings, value source Region) so it is not asked |
| `compartment_ocid` | filled by OneCloud | Hide it in the variable mapping: OneCloud sets TF_VAR_compartment_ocid from the cloud account |
| `web_shape`, `app_shape` | select box | shape:OCPUs:memory GB, default `VM.Standard.E4.Flex:1:8`. `VM.Standard.A1.Flex:1:6` is Always Free |
| `web_boot_volume_size_in_gbs`, `app_boot_volume_size_in_gbs` | number | Default 50 GB (the OCI minimum), grow only |
| `app_data_disk_sizes_gb` | list | Default one 50 GB block volume, up to 4 |
| `ingress_ports` | list | TCP ports of the web tier, default 80 and 443 |
| `ingress_source_cidr` | text | Who may reach those ports, default anywhere |
| `app_port` | number | Default 8080 |
| `ssh_public_key` | text | Optional; empty means no key for the opc user (use the Bastion service) |
| `vcn_cidr`, `public_subnet_cidr`, `private_subnet_cidr` | text | Defaults in `10.70.0.0/16` |
| `cost_centre` | text | Default `CC-1001`, put on every resource as the `cost_centre` free form tag |
| `test_tag` | text | Optional. Puts an `OneCloudTest` tag on every resource for test clean up |
| `tags` | filled by OneCloud | Hide it in the variable mapping. Applied as free form tags |

## Day-2 operations it lights up

Variables named `<tier>_<setting>` belong to the server whose Terraform name is `<tier>` (`oci_core_instance.web` and `.app`), so an operation run on one server changes only that server.

| Operation | Variable |
|---|---|
| Resize | `web_shape`, `app_shape` as shape:OCPUs:memory GB (OCI reboots the server for a new shape) |
| Expand disk | `web_boot_volume_size_in_gbs`, `app_boot_volume_size_in_gbs` (boot volumes grow online; extend the file system afterwards) |
| Add a data disk | `app_data_disk_sizes_gb` (app server, paravirtualized attachment) |
| Open a port, Close a port | `ingress_ports` (web tier, one network security group rule per port) |
| Start, Stop, Restart | either server, through the OCI CLI on the MID Server |

## Outputs

`vcn_id`, `web_public_ip`, `web_private_ip`, `app_private_ip`, `web_instance_id`, `app_instance_id`, `data_bucket`, `open_ports` and `web_url`.

## Costs

Two flexible shape servers (OCPU hours and memory GB hours), two 50 GB boot volumes and one 50 GB block volume, and an empty Object Storage bucket. The ephemeral public IP address and the VCN cost nothing. Always Free covers Arm `VM.Standard.A1.Flex` up to 4 OCPUs and 24 GB of memory in total and 200 GB of block and boot volume storage in total, in the home region only; pick `VM.Standard.A1.Flex:1:6` for both tiers to stay inside it (three volumes of 50 GB). A stopped server is not billed for OCPUs and memory on standard shapes; volumes are still billed.

## Provider version

Written for `oracle/oci` 6.x to 9.x (validated with 9.10 on Terraform 1.11). The credential is not a template variable: the provider reads TF_VAR_tenancy_ocid, TF_VAR_user_ocid, TF_VAR_fingerprint, TF_VAR_private_key and TF_VAR_region from the environment OneCloud sets. Each web port is a separate `oci_core_network_security_group_security_rule`.

## Try it locally

```
export TF_VAR_tenancy_ocid=ocid1.tenancy.oc1..aaaa TF_VAR_user_ocid=ocid1.user.oc1..aaaa
export TF_VAR_fingerprint=12:34:... TF_VAR_private_key="$(cat oci_api_key.pem)"
export TF_VAR_compartment_ocid=ocid1.compartment.oc1..aaaa
terraform init
terraform plan -var name=demo3t -var region=uk-london-1
```
