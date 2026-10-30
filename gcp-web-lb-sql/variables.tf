variable "project" {
  description = "Google Cloud project id. Leave empty to use the project of the OneCloudify cloud account (GOOGLE_PROJECT)."
  type        = string
  default     = ""

  validation {
    condition     = var.project == "" || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project))
    error_message = "project must be empty or a Google Cloud project id (6 to 30 lowercase letters, digits and hyphens)."
  }
}

variable "region" {
  description = "Google Cloud region, for example europe-west2. OneCloudify fills it from the region picked on the order."
  type        = string
  default     = "europe-west2"

  validation {
    condition     = can(regex("^[a-z]+-[a-z]+[0-9]{1,2}$", var.region))
    error_message = "region must be a Google Cloud region such as europe-west2."
  }
}

variable "zone_suffix" {
  description = "Zone letter inside the region for the web servers, for example a for europe-west2-a."
  type        = string
  default     = "a"

  validation {
    condition     = contains(["a", "b", "c", "d", "f"], var.zone_suffix)
    error_message = "zone_suffix must be a, b, c, d or f."
  }
}

variable "name" {
  description = "Base name for the deployment. Lowercase letters, digits and hyphens, 2 to 20 characters, starting with a letter."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,19}$", var.name))
    error_message = "name must be 2 to 20 characters of lowercase letters, digits and hyphens, starting with a letter."
  }
}

variable "subnet_cidr" {
  description = "Address range of the web subnet."
  type        = string
  default     = "10.91.1.0/24"

  validation {
    condition     = can(cidrhost(var.subnet_cidr, 0))
    error_message = "subnet_cidr must be a valid CIDR block."
  }
}

variable "web_server_count" {
  description = "Number of web servers behind the load balancer."
  type        = number
  default     = 2

  validation {
    condition     = var.web_server_count >= 1 && var.web_server_count <= 4
    error_message = "web_server_count must be from 1 to 4."
  }
}

variable "web_machine_type" {
  description = "Machine type of every web server."
  type        = string
  default     = "e2-small"

  validation {
    condition     = contains(["e2-micro", "e2-small", "e2-medium", "n2-standard-2"], var.web_machine_type)
    error_message = "web_machine_type must be e2-micro, e2-small, e2-medium or n2-standard-2."
  }
}

variable "web_boot_disk_size" {
  description = "Boot disk size of each web server in GB. It can grow, never shrink."
  type        = number
  default     = 10

  validation {
    condition     = var.web_boot_disk_size >= 10 && var.web_boot_disk_size <= 100
    error_message = "web_boot_disk_size must be from 10 to 100."
  }
}

variable "web_port" {
  description = "TCP port the load balancer and the web servers listen on."
  type        = number
  default     = 80

  validation {
    condition     = var.web_port >= 1 && var.web_port <= 65535
    error_message = "web_port must be from 1 to 65535."
  }
}

variable "ingress_source_cidr" {
  description = "Where the load balancer may be reached from, a CIDR block. 0.0.0.0/0 means anywhere."
  type        = string
  default     = "0.0.0.0/0"

  validation {
    condition     = can(cidrhost(var.ingress_source_cidr, 0))
    error_message = "ingress_source_cidr must be a valid CIDR block."
  }
}

variable "db_version" {
  description = "Database engine and version of the Cloud SQL instance."
  type        = string
  default     = "POSTGRES_16"

  validation {
    condition     = contains(["POSTGRES_16", "POSTGRES_15", "MYSQL_8_0"], var.db_version)
    error_message = "db_version must be POSTGRES_16, POSTGRES_15 or MYSQL_8_0."
  }
}

variable "db_tier" {
  description = "Cloud SQL machine tier: db-f1-micro and db-g1-small are shared core, db-custom-<vCPUs>-<memory MB> are dedicated."
  type        = string
  default     = "db-custom-1-3840"

  validation {
    condition     = contains(["db-f1-micro", "db-g1-small", "db-custom-1-3840", "db-custom-2-7680", "db-custom-4-15360"], var.db_tier)
    error_message = "db_tier must be db-f1-micro, db-g1-small, db-custom-1-3840, db-custom-2-7680 or db-custom-4-15360."
  }
}

variable "db_availability" {
  description = "ZONAL for one zone, REGIONAL for a standby in a second zone (high availability, about twice the price)."
  type        = string
  default     = "ZONAL"

  validation {
    condition     = contains(["ZONAL", "REGIONAL"], var.db_availability)
    error_message = "db_availability must be ZONAL or REGIONAL."
  }
}

variable "db_disk_type" {
  description = "Storage type of the database: PD_SSD or PD_HDD."
  type        = string
  default     = "PD_SSD"

  validation {
    condition     = contains(["PD_SSD", "PD_HDD"], var.db_disk_type)
    error_message = "db_disk_type must be PD_SSD or PD_HDD."
  }
}

variable "db_disk_size_gb" {
  description = "Database storage in GB. It can grow, never shrink."
  type        = number
  default     = 10

  validation {
    condition     = var.db_disk_size_gb >= 10 && var.db_disk_size_gb <= 500
    error_message = "db_disk_size_gb must be from 10 to 500."
  }
}

variable "db_backups" {
  description = "Daily automated backups of the database (backup storage is billed on top)."
  type        = bool
  default     = true
}

variable "db_name" {
  description = "Name of the application database created in the instance."
  type        = string
  default     = "app"

  validation {
    condition     = can(regex("^[a-z][a-z0-9_]{0,62}$", var.db_name))
    error_message = "db_name must start with a letter and hold up to 63 lowercase letters, digits or underscores."
  }
}

variable "test_tag" {
  description = "Value of the onecloudtest label put on every resource, so a test can find and remove what it made. Leave empty outside tests."
  type        = string
  default     = ""

  validation {
    condition     = can(regex("^[a-z0-9_-]{0,63}$", var.test_tag))
    error_message = "test_tag must be up to 63 lowercase letters, digits, underscores or hyphens (a Google label value)."
  }
}

variable "cost_centre" {
  description = "Cost centre the resources are charged to, put on every resource as the cost_centre label (in lower case, as Google labels require)."
  type        = string
  default     = "CC-1001"

  validation {
    condition     = can(regex("^[A-Za-z0-9-]{1,20}$", var.cost_centre))
    error_message = "cost_centre must be 1 to 20 letters, digits or hyphens."
  }
}

variable "tags" {
  description = "Tags applied to every resource as Google labels. OneCloudify passes the deployment tags here, including the onecloud_deployment correlation tag. Keys and values are put in lower case and other characters become underscores, as Google labels require."
  type        = map(string)
  default     = {}
}
