# AWS EKS basic

Creates an Amazon EKS cluster in the default VPC with one managed node group of 1 to 3 nodes, plus the cluster and node IAM roles EKS needs. Pick the Kubernetes version and the number of nodes when you order. Remove deletes the node group, the cluster and the two roles. Needs an AWS cloud account in OneCloudify whose key may create EKS clusters and IAM roles.

Tested on 18 October 2026 in an AWS account on the Free plan (eu-north-1): the cluster and roles were created, but the node group failed after 30 minutes because that account launches only free tier eligible instance types and t3.medium is not one (node group health: AsgInstanceLaunchFailures, "The specified instance type is not eligible for Free Tier"). Remove then deleted everything. On a Free plan account pick t3.small, c7i-flex.large or m7i-flex.large (`aws ec2 describe-instance-types --filters Name=free-tier-eligible,Values=true` lists them). Scale and upgrade are not proven on AWS yet.

## What the requester fills in

| Variable | Control in the catalog | Notes |
|---|---|---|
| `name` | text, mandatory | Cluster name, 3 to 40 characters |
| `region` | filled by OneCloudify | From the region picked on the order |
| `kubernetes_version` | select box | 1.35, 1.36 (default) or 1.37, EKS standard support |
| `node_count` | number | 1 (default) to 3 |
| `node_instance_type` | select box | t3.medium (default), t3.large, or t3.small, c7i-flex.large, m7i-flex.large for Free plan accounts |
| `cost_centre` | text | Default `CC-1001` |
| `test_tag` | text | Optional. Puts an `OneCloudTest` tag on every resource for test clean up |
| `tags` | filled by OneCloudify | Hide it in the variable mapping |

## Day-2 operations it lights up

| Operation | How |
|---|---|
| Scale node pool | sets `node_count`, the desired size of the node group |
| Upgrade Kubernetes version | sets `kubernetes_version` for the control plane and the node group, one minor version at a time |

EKS has no stop for a cluster. Versions checked against the Amazon EKS Kubernetes version calendar on 17 October 2026.
