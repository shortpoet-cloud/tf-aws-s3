variable "bucket" {
  type        = string
  description = "Name of the bucket this baseline applies to."
}

variable "kms_key_arn" {
  type        = string
  description = "ARN of a KMS key for SSE-KMS. Empty selects SSE-S3 (AES256)."
  default     = ""
}

variable "versioning_enabled" {
  type        = bool
  description = "Enable versioning. False leaves a never-versioned bucket unversioned (Disabled)."
  default     = true
}

variable "allow_public_policy" {
  type        = bool
  description = "Allow a public bucket policy (a website bucket). Public ACLs stay blocked either way."
  default     = false
}
