# Settings written into the configuration object (s3://<bucket>/<object_prefix>settings.json).
# They exercise every Terraform type and literal form OneCloudify has to read.

variable "extra_tags" {
  description = "Extra tags for every resource"
  type        = map(string)
  default     = {}
}

variable "quoted_keys" {
  description = "Labels with keys that need quotes"
  type        = map(string)
  default = {
    "app.kubernetes.io/name" = "landing-zone"
    "Cost Centre"            = "CC-100"
    plain_key                = "yes"
  }
}

variable "quotas" {
  description = "Quotas per object type"
  type        = map(number)
  default = {
    buckets = 2
    objects = 50
  }
}

variable "retention_by_env" {
  description = "Retention days per environment"
  type        = map(number)
  default     = { dev = 7, test = 14, prod = 30 }
}

variable "feature_flags" {
  description = "Features to switch on"
  type        = set(string)
  default     = ["audit", "metrics"]

  validation {
    condition     = alltrue([for f in var.feature_flags : contains(["audit", "metrics", "tracing"], f)])
    error_message = "Features are audit, metrics and tracing."
  }
}

variable "maintenance_window" {
  description = "Maintenance window as day, hour and whether it is on"
  type        = tuple([string, number, bool])
  default     = ["sun", 3, true]
}

variable "owner_contact" {
  description = "Who to call about this landing zone"
  type = object({
    name  = string
    email = string
    phone = optional(string)
  })
}

variable "app_settings" {
  description = "Free form settings passed to the application as JSON"
  type        = any
  default = {
    log_level = "info"
    limits    = { cpu = 2, memory_gb = 4 }
    endpoints = ["https://api.example.com", "https://auth.example.com"]
  }
}

variable "notes_json" {
  description = "Anything else, any type"
  type        = any
  default     = null
}

# Untyped variables: Terraform takes the type of whatever value it is given.
variable "legacy_mode" {
  default = "off"
}

variable "legacy_ports" {
  default = [80, 8080]
}

variable "legacy_limits" {
  default = { small = 1, large = 4 }
}

variable "object_prefix" {
  description = "Folder in the bucket for the configuration object; ends with a slash"
  type        = string
  default     = "configs/"

  validation {
    condition     = can(regex("/$", var.object_prefix)) && length(var.object_prefix) <= 40
    error_message = "End the prefix with a slash and keep it to 40 characters."
  }
}

variable "bucket_suffix" {
  description = "Optional suffix for the bucket name"
  type        = string
  default     = ""

  validation {
    condition     = length(var.bucket_suffix) <= 12
    error_message = "Keep the suffix to 12 characters."
  }
}

variable "motd" {
  description = "Message of the day shown on login (indented heredoc)"
  type        = string
  default     = <<-EOT
    Welcome to the landing zone.
      Indented line kept relative.
    Contact: platform-team@example.com
  EOT
}

variable "banner" {
  description = "Banner text with escaped template markers"
  type        = string
  default     = <<EOT
Environment: $${environment}
Directive kept as text: %%{ if x }
EOT
}

variable "greeting" {
  description = "Greeting in several scripts"
  type        = string
  default     = "Hej från Göteborg, Grüße, こんにちは ✓"
}

variable "computed_default" {
  description = "Default built from a constant template"
  type        = string
  default     = "zone-${"a"}%{if true}-1%{endif}"
}

variable "long_text" {
  description = "A very long default value"
  type        = string
  default     = "This default is deliberately long so that the order form, the catalog variable default and the run inputs all have to carry more than five hundred characters without cutting anything off. It repeats a few facts about the landing zone: it has a VPC, three subnets, a network ACL, a security group, a bucket with versioning and a lifecycle rule, and one configuration object that lists every value Terraform received. Nothing here costs money while it sits idle, and Remove deletes all of it including the objects in the bucket. End of the long default."
}

variable "count_per_az" {
  description = "Copies per availability zone"
  type        = number
  default     = 1

  validation {
    condition     = contains([1, 2], var.count_per_az)
    error_message = "Use 1 or 2."
  }
}

variable "ratio" {
  description = "Weight between 0 and 1"
  type        = number
  default     = 0.25

  validation {
    condition     = var.ratio >= 0 && var.ratio <= 1
    error_message = "Use a number from 0 to 1."
  }
}

variable "audit_bucket_arn" {
  description = "ARN of a central audit bucket, if there is one"
  type        = string
  default     = null
  nullable    = true
}
