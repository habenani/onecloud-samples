# AWS VM (create only demo)

Creates one Amazon Linux 2023 EC2 instance (t3.micro by default) with an 8 GB gp3 root disk in the default VPC of the region you pick. It creates no network and no security group: AWS puts the instance in a default subnet with the VPC's default security group.

This is a create only demo template. It was written for a test access key that may create instances and tags but may not stop, change or delete anything. With a key like that the order works, and every day-2 action and Remove fails in AWS. Whoever owns the AWS account has to terminate the instance by hand. Use the `aws-vpc` sample or your own template when the key has the full permission set (see the AWS end to end guide, Permissions for day-2 actions).

## What the requester fills in

| Variable | Control in the catalog | Notes |
|---|---|---|
| `name` | text, mandatory | Name tag of the instance |
| `test_tag` | text | Value of the `OneCloudTest` tag, so the leftovers can be found later |
| `instance_type` | select box | `t3.micro` or `t3.small` |
| `region` | filled by OneCloudify | From the region picked on the order, default `us-east-1` |
| `tags` | filled by OneCloudify | Deployment tags, including `onecloud_deployment` |

Tags on the instance and its root volume: `Name`, `OneCloudTest`, `Owner = OneCloudify test` and the tags OneCloudify passes.

## Outputs

`instance_id`, `private_ip`, `public_ip` and `availability_zone`.

## Permissions the key needs

`ec2:RunInstances`, `ec2:CreateTags`, `ec2:DescribeImages`, `ec2:DescribeInstances`, `ec2:DescribeInstanceAttribute`, `ec2:DescribeInstanceTypes`, `ec2:DescribeVolumes`, `ec2:DescribeTags`, `ec2:DescribeInstanceCreditSpecifications` and `sts:GetCallerIdentity`. Removing it needs `ec2:TerminateInstances` as well.

## Try it locally

```
export AWS_ACCESS_KEY_ID=... AWS_SECRET_ACCESS_KEY=...
terraform init
terraform plan -var name=demo-vm -var test_tag=local-test
```
