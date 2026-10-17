# AWS EKS basic

Creates an Amazon EKS cluster in the default VPC with one managed node group of 1 to 3 nodes, plus the cluster and node IAM roles EKS needs. Pick the Kubernetes version and the number of nodes when you order. Remove deletes the node group, the cluster and the two roles. Needs an AWS cloud account in OneCloud whose key may create EKS clusters and IAM roles.

Not proven live by OneCloud yet: the test account's key cannot create or delete IAM roles or EKS clusters, so only a Terraform plan was run (17 October 2026).

## What the requester fills in

| Variable | Control in the catalog | Notes |
|---|---|---|
| `name` | text, mandatory | Cluster name, 3 to 40 characters |
| `region` | filled by OneCloud | From the region picked on the order |
| `kubernetes_version` | select box | 1.35, 1.36 (default) or 1.37, EKS standard support |
| `node_count` | number | 1 (default) to 3 |
| `node_instance_type` | select box | t3.medium (default) or t3.large |
| `cost_centre` | text | Default `CC-1001` |
| `test_tag` | text | Optional. Puts an `OneCloudTest` tag on every resource for test clean up |
| `tags` | filled by OneCloud | Hide it in the variable mapping |

## Day-2 operations it lights up

| Operation | How |
|---|---|
| Scale node pool | sets `node_count`, the desired size of the node group |
| Upgrade Kubernetes version | sets `kubernetes_version` for the control plane and the node group, one minor version at a time |

EKS has no stop for a cluster. Versions checked against the Amazon EKS Kubernetes version calendar on 17 October 2026.
