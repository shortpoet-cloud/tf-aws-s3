variable "bucket" {
  type        = string
  description = "Name of the bucket whose default encryption this sets."
}

variable "kms_key_arn" {
  type        = string
  description = "ARN of a KMS key for SSE-KMS. Empty selects SSE-S3 (AES256)."
  default     = ""
}
