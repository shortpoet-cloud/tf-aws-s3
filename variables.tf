variable "bucket_name" {
  type        = string
  description = "The name of the S3 bucket"
}

variable "tags" {
  type        = map(string)
  description = "The tags to apply to the S3 bucket"
}

variable "allowed_ips" {
  type        = list(string)
  description = "Source IPs allowed to get objects"
}

variable "allowed_user_ids" {
  type        = list(string)
  description = "aws:userId patterns allowed to list and get objects"
}

variable "allow_public_policy" {
  type        = bool
  description = "Allow the bucket policy to count as public (its Principal \"*\" statements are IP- and user-conditioned). Public ACLs stay blocked."
  default     = false
}

variable "versioning_enabled" {
  type        = bool
  description = "Enable versioning. False leaves a never-versioned bucket unversioned."
  default     = true
}

variable "kms_key_arn" {
  type        = string
  description = "The ARN of the KMS key to use when encrypting objects in the bucket. If not provided, S3 uses SSE-S3 (AES256)."
  default     = ""
}

variable "force_destroy" {
  type        = bool
  description = "Whether all objects should be deleted from the bucket so that the bucket can be destroyed without error. These objects are not recoverable."
  default     = false
}
