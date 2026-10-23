# Loaded by Terraform automatically, before any *.auto.tfvars file.
log_retention_days = 14
bucket_suffix      = "-tf"

extra_tags = {
  team = "platform"
}

# A required variable with a value here is no longer required when the template runs.
owner_contact = {
  name  = "Platform team"
  email = "platform-team@example.com"
}

# Placeholder only. The requester's secret replaces it.
app_secret = "placeholder-not-a-secret"
