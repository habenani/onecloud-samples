# Oracle Cloud web servers with load balancer and Autonomous Database

Creates web servers in Oracle Cloud Infrastructure behind a flexible load balancer, in a VCN of their own: the servers sit in a private subnet without public IP addresses, a NAT gateway lets them reach the internet for updates, and an Autonomous Database (transaction processing, ECPU) has a private endpoint in the same subnet, reachable from the web servers only. Remove deletes everything, the database included. Needs an Oracle Cloud cloud account in OneCloudify whose user may manage networks, instances, load balancers and autonomous databases in the account's compartment: cloud-bootstrap/oci-bootstrap.sh writes a policy that lets it manage all resources in the compartment, which covers these. With a narrower policy of your own, the group also needs `manage load-balancers` and `manage autonomous-database-family` in the compartment.

## What the requester fills in

| Variable | Control in the catalog | Notes |
|---|---|---|
| `name` | text, mandatory | Base name, 2 to 20 lowercase characters, starting with a letter |
| `region` | text | Map it to the account region (Variable mappings, value source Region) so it is not asked |
| `compartment_ocid` | filled by OneCloudify | Hide it in the variable mapping: OneCloudify sets TF_VAR_compartment_ocid from the cloud account |
| `web_server_count` | number | 1 to 4 web servers, default 2 |
| `web_shape` | select box | shape:OCPUs:memory GB, default `VM.Standard.E4.Flex:1:8` |
| `web_boot_volume_size_in_gbs` | number | Default 50 GB (the OCI minimum), grow only |
| `web_port` | number | Port of the load balancer listener and nginx on the servers, default 80 |
| `ingress_source_cidr` | text | Who may reach the load balancer, default anywhere |
| `lb_bandwidth_mbps` | select box | 10 (default), 50, 100 or 400 Mbps |
| `db_ecpu` | select box | 2 (default), 4 or 8 ECPUs |
| `db_storage_gb` | number | 20 to 1024 GB, default 20 |
| `db_license_model` | select box | LICENSE_INCLUDED (default) or BRING_YOUR_OWN_LICENSE |
| `cost_centre` | text | Default `CC-1001`, put on every resource as the `cost_centre` free form tag |
| `test_tag` | text | Optional. Puts an `OneCloudTest` tag on every resource for test clean up |
| `tags` | filled by OneCloudify | Hide it in the variable mapping. Applied as free form tags |

## Day-2 operations it lights up

| Operation | Variable |
|---|---|
| Resize | `web_shape` as shape:OCPUs:memory GB (every web server; OCI reboots each one) |
| Start, Stop, Restart | a web server, through the OCI CLI on the MID Server |

## Outputs

`vcn_id`, `load_balancer_ip`, `web_url`, `web_private_ips`, `web_instance_ids`, `nat_gateway_id`, `db_id` and `db_private_endpoint`.

## Costs

The order form estimate prices each part: the web servers (OCPU and memory hours) and their boot volumes (storage and performance units), the flexible load balancer (base hours plus bandwidth; the first 10 Mbps load balancer of a tenancy is Always Free) and the Autonomous Database (ECPU hours and storage). The NAT gateway, the internet gateway and the public IP address of the load balancer have no charge. Stop ends the OCPU and memory charge of a web server only; the load balancer and the database keep running.

## Provider version

Written for `oracle/oci` 6.x to 9.x and `hashicorp/random` 3.x (validated on Terraform 1.11). The credential is not a template variable: the provider reads TF_VAR_tenancy_ocid, TF_VAR_user_ocid, TF_VAR_fingerprint, TF_VAR_private_key and TF_VAR_region from the environment OneCloudify sets. The database has no admin password in Terraform: set it in the OCI Console (or from OCI Vault) when the team first connects, so no database secret is kept in the Terraform state.

## Try it locally

```
export TF_VAR_tenancy_ocid=ocid1.tenancy.oc1..aaaa TF_VAR_user_ocid=ocid1.user.oc1..aaaa
export TF_VAR_fingerprint=12:34:... TF_VAR_private_key="$(cat oci_api_key.pem)"
export TF_VAR_compartment_ocid=ocid1.compartment.oc1..aaaa
terraform init
terraform plan -var name=shop-web -var region=uk-london-1
```
