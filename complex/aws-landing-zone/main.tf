data "aws_caller_identity" "current" {}

module "label" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  namespace   = "oc"
  stage       = var.environment
  name        = var.name
  tags        = merge(var.extra_tags, var.tags)
  label_order = ["namespace", "name", "stage"]
}

locals {
  tags = merge(module.label.tags, {
    owner   = var.owner_email
    project = var.project_code
  }, var.cost_centre == null ? {} : { cost_centre = var.cost_centre })

  bucket_name = substr(lower("${module.label.id}-${data.aws_caller_identity.current.account_id}${var.bucket_suffix}"), 0, 63)

  # ephemeral values may only flow into other ephemeral places
  token_state = var.api_token == null ? "absent" : "present"

  # every value Terraform received, written to the bucket so a run can be checked
  received = {
    name               = var.name
    region             = var.region
    environment        = var.environment
    project_code       = var.project_code
    owner_email        = var.owner_email
    cost_centre        = var.cost_centre
    log_retention_days = var.log_retention_days
    lifecycle_days     = var.lifecycle_days
    enable_versioning  = var.enable_versioning
    force_destroy      = var.force_destroy
    app_secret_sha256  = sha256(var.app_secret)
    tags               = var.tags
    vpc                = var.vpc
    subnets            = var.subnets
    availability_zones = var.availability_zones
    max_az_count       = var.max_az_count
    network_acl_rules  = var.network_acl_rules
    dns_servers        = var.dns_servers
    region_pair        = var.region_pair
    allowed_ports      = var.allowed_ports
    admin_cidrs        = var.admin_cidrs
    ingress_rules      = var.ingress_rules
    extra_tags         = var.extra_tags
    quoted_keys        = var.quoted_keys
    quotas             = var.quotas
    retention_by_env   = var.retention_by_env
    feature_flags      = var.feature_flags
    maintenance_window = var.maintenance_window
    owner_contact      = var.owner_contact
    app_settings       = var.app_settings
    notes_json         = var.notes_json
    legacy_mode        = var.legacy_mode
    legacy_ports       = var.legacy_ports
    legacy_limits      = var.legacy_limits
    object_prefix      = var.object_prefix
    bucket_suffix      = var.bucket_suffix
    motd               = var.motd
    banner             = var.banner
    greeting           = var.greeting
    computed_default   = var.computed_default
    long_text          = var.long_text
    count_per_az       = var.count_per_az
    ratio              = var.ratio
    audit_bucket_arn   = var.audit_bucket_arn
  }
}

resource "aws_s3_bucket" "config" {
  bucket        = local.bucket_name
  force_destroy = var.force_destroy
  tags          = local.tags
}

resource "aws_s3_bucket_public_access_block" "config" {
  bucket                  = aws_s3_bucket.config.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "config" {
  bucket = aws_s3_bucket.config.id
  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "config" {
  bucket = aws_s3_bucket.config.id

  rule {
    id     = "old-versions"
    status = "Enabled"
    filter {}
    noncurrent_version_expiration {
      noncurrent_days = var.lifecycle_days
    }
  }

  depends_on = [aws_s3_bucket_versioning.config]
}

resource "aws_s3_object" "settings" {
  bucket       = aws_s3_bucket.config.id
  key          = "${var.object_prefix}settings.json"
  content      = jsonencode(local.received)
  content_type = "application/json"
}
