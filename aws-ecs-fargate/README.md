# AWS ECS on Fargate

Runs a container from a public image as an Amazon ECS service on Fargate in the default VPC: an ECS cluster, a task definition, a security group that opens the container port, and the service with public IP addresses. Pick the image, the task size and the number of tasks when you order. Remove deletes all of it. Needs an AWS cloud account in OneCloud whose key may manage ECS and EC2 security groups.

Proven live on 18 October 2026 in eu-north-1: order (service ACTIVE, 1 Fargate task in the default VPC, about 2 minutes), Scale service to 2 (2 running) and Remove (cluster deleted, no active task definition or security group left).

## What the requester fills in

| Variable | Control in the catalog | Notes |
|---|---|---|
| `name` | text, mandatory | Cluster and service name, 3 to 32 characters |
| `region` | filled by OneCloud | From the region picked on the order |
| `image` | text | Default `public.ecr.aws/nginx/nginx:stable` |
| `desired_count` | number | Tasks to run, 0 to 10, default 1 |
| `task_cpu`, `task_memory` | select box | 256 and 512 by default |
| `port` | number | Default 80 |
| `cost_centre`, `test_tag`, `tags` | as in the other samples | |

## Day-2 operations it lights up

| Operation | How |
|---|---|
| Scale service | sets `desired_count` through Terraform; 0 keeps the service but runs nothing |
| Update | changes `image`, `task_cpu` or `task_memory`; the service rolls to a new task definition revision |
