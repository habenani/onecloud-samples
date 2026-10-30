# vSphere virtual machine

Creates one virtual machine in a vCenter datacenter: cloned from a VM template when you name one, or an empty VM (no operating system) for a lab. It connects to one port group and writes the OneCloudify tags into the VM notes. Needs a vSphere cloud account in OneCloudify (one vCenter, set up with `vsphere-bootstrap.sh` from the OneCloudify repository).

## What the requester fills in

| Variable | Control in the catalog | Notes |
|---|---|---|
| `name` | text, mandatory | VM name, 2 to 63 letters, digits and hyphens |
| `datacenter` | filled by OneCloudify | Map it to the account region (Variable mappings, value source Region): the region code is the datacenter name |
| `resource_pool` | text, mandatory | `Cluster1/Resources`, `Cluster1/Resources/Web` or `esx01/Resources` |
| `datastore` | text, mandatory | Datastore name |
| `network` | text | Port group, default `VM Network` |
| `folder` | text | VM folder under the datacenter's vm folder, empty for the root |
| `template` | text | VM template to clone; empty creates an empty VM |
| `num_cpus` | select box | 1, 2, 4 or 8 |
| `memory_mb` | select box | 1024 to 16384 |
| `disk_gb` | text | Default 40 |
| `guest_id` | text | Only for an empty VM, default `otherLinux64Guest` |
| `tags` | filled by OneCloudify | Hide it in the variable mapping |

## Outputs

`vm_id` (the instance UUID, which power actions and govc use), `moid` (vm-123, what Discovery keeps) and `private_ip` (empty without VMware Tools).

## Resource types OneCloudify maps to the CMDB

`vsphere_virtual_machine` has a row in the OneCloudify resource type map, so the post apply step writes a `cmdb_ci_vmware_instance` CI straight away. The platform's vCenter discovery (Discover datacenters on the service account) fills in the rest of the vCenter inventory. Start, Stop, Restart and Resize work on it (size is CPUs x memory in MB, for example 2x4096).

## Tags

vSphere has no free form tags on a VM. The `tags` map goes into the VM notes (annotation) as `key=value` lines, so anyone in the vSphere Client sees the deployment number. vSphere tags (category and tag objects) can be added with `vsphere_tag` resources when your vCenter has the categories.

## Provider version

Written for `vmware/vsphere` 2.x. The provider reads `VSPHERE_SERVER`, `VSPHERE_USER`, `VSPHERE_PASSWORD` and `VSPHERE_ALLOW_UNVERIFIED_SSL` from the environment, which OneCloudify exports from the cloud account and its VMware credential.

## Try it locally

```
export VSPHERE_SERVER=vcenter.example.com VSPHERE_USER=onecloud-onecloud@vsphere.local
read -rs VSPHERE_PASSWORD && export VSPHERE_PASSWORD
terraform init
terraform plan -var name=web-lab-01 -var datacenter=Datacenter1 -var resource_pool=Cluster1/Resources -var datastore=datastore1
```
