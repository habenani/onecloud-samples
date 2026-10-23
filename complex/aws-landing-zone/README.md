# AWS landing zone (complex inputs)

Creates a small AWS landing zone: a VPC with three subnets, a network ACL, an application security group and a private S3 bucket with versioning and a lifecycle rule. Nothing in it costs money while it sits idle.

The bucket holds one object, `configs/settings.json`, with every value Terraform received, so you can check what the order form sent.

## For template authors

This template exercises every variable type and file layout OneCloud reads: variables split over several `.tf` files, `terraform.tfvars`, `*.auto.tfvars` and `*.auto.tfvars.json`, a local module, a registry module, heredoc and unicode defaults, sensitive and ephemeral variables and validation blocks of every kind.

| File | Purpose |
|---|---|
| `variables.tf`, `network.tf`, `security.tf`, `extra-variables.tf` | Variables (45) and resources |
| `terraform.tfvars`, `a-defaults.auto.tfvars`, `z-overrides.auto.tfvars.json` | Values Terraform loads automatically |
| `example.tfvars` | Not loaded automatically |
| `modules/subnet-set` | Local module |
| `docs/`, `scripts/` | Not part of the template |
