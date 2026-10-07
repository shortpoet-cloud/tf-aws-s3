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
    condition     = alltrue([for tenant in var.tenants : can(regex("^[a-z0-9][a-z0-9-]{0,15}$", tenant))])
    error_message = "Each tenant must be 1-16 lowercase letters, digits or hyphens, starting with a letter or digit."
  }
}

variable "identity_center_role_arn" {
  type        = string
  description = "ARN of the IAM Identity Center permission-set role that alone may assume the writer and restore roles."

  validation {
    condition     = can(regex("^arn:aws[a-z-]*:iam::[0-9]{12}:role/aws-reserved/sso\\.amazonaws\\.com/([a-z0-9-]+/)?AWSReservedSSO_[A-Za-z0-9+=,.@_-]+$", var.identity_center_role_arn))
    error_message = "identity_center_role_arn must be an IAM Identity Center permission-set role (role/aws-reserved/sso.amazonaws.com/.../AWSReservedSSO_...)."
  }
}

variable "kms_key_arn" {
  type        = string
  description = "ARN of a KMS key for SSE-KMS. Empty selects SSE-S3 (AES256)."
  default     = ""
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to every taggable resource."
  default     = {}
}
