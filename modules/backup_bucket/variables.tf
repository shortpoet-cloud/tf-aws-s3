variable "bucket_name" {
  type        = string
  description = "Globally unique name of the backup bucket."

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.bucket_name))
    error_message = "bucket_name must be a valid S3 bucket name (3-63 lowercase letters, digits, dots or hyphens)."
  }
}

variable "name" {
  type        = string
  description = "Prefix for the IAM role, policy and user names (<name>-<tenant>-<purpose>)."

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{0,31}$", var.name))
    error_message = "name must be 1-32 lowercase letters, digits or hyphens, starting with a letter or digit."
  }
}

variable "tenants" {
  type        = set(string)
  description = "Tenant ids. Each tenant owns the key prefix <tenant>/ and gets its own writer role, restore role and break-glass user."

  validation {
    condition     = length(var.tenants) > 0
    error_message = "tenants must name at least one tenant."
  }

  # The tenant id becomes an IAM resource pattern and an s3:prefix condition,
  # so it must not carry wildcard or path characters that would widen either.
  validation {
    condition     = alltrue([for tenant in var.tenants : can(regex("^[a-z0-9][a-z0-9-]*$", tenant))])
    error_message = "Each tenant must be lowercase letters, digits or hyphens, starting with a letter or digit."
  }

  # The longest IAM name built from a tenant is the break-glass user,
  # <name>-<tenant>-break-glass, and IAM user and role names stop at 64.
  validation {
    condition     = alltrue([for tenant in var.tenants : length("${var.name}-${tenant}-break-glass") <= 64])
    error_message = "Each tenant must keep <name>-<tenant>-break-glass within IAM's 64-character name limit."
  }
}

variable "identity_center_role_arn" {
  type        = string
  description = "ARN of the IAM Identity Center permission-set role that alone may assume the writer and restore roles. tf-iam's identity_center_role validates it."
}

variable "kms_key_arn" {
  type        = string
  description = "ARN of a KMS key for SSE-KMS. Empty selects SSE-S3 (AES256)."
  default     = ""
}

variable "noncurrent_version_retention" {
  type = map(object({
    prefix                    = string
    noncurrent_days           = number
    newer_noncurrent_versions = number
  }))
  description = "Lifecycle rules, keyed by rule id, that expire noncurrent versions under a prefix inside one tenant. A version expires once it has been noncurrent for noncurrent_days and newer_noncurrent_versions newer noncurrent versions of its key exist. Empty keeps every version."
  default     = {}

  # A prefix outside every tenant, or one that stops short of the tenant's
  # trailing slash, would expire another tenant's history.
  validation {
    condition = alltrue([
      for rule in values(var.noncurrent_version_retention) :
      anytrue([for tenant in var.tenants : startswith(rule.prefix, "${tenant}/")])
    ])
    error_message = "Each rule's prefix must start with a declared tenant's prefix, <tenant>/."
  }

  validation {
    condition = alltrue([
      for rule in values(var.noncurrent_version_retention) :
      rule.noncurrent_days >= 1 && floor(rule.noncurrent_days) == rule.noncurrent_days
    ])
    error_message = "noncurrent_days must be a whole number of at least 1."
  }

  # S3 keeps at most 100 newer noncurrent versions in a rule.
  validation {
    condition = alltrue([
      for rule in values(var.noncurrent_version_retention) :
      rule.newer_noncurrent_versions >= 1 && rule.newer_noncurrent_versions <= 100 && floor(rule.newer_noncurrent_versions) == rule.newer_noncurrent_versions
    ])
    error_message = "newer_noncurrent_versions must be a whole number from 1 to 100."
  }

  validation {
    condition     = !contains(keys(var.noncurrent_version_retention), local.abort_incomplete_multipart_uploads_rule_id)
    error_message = "The rule id abort-incomplete-multipart-uploads is the module's own."
  }
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to every taggable resource."
  default     = {}
}
