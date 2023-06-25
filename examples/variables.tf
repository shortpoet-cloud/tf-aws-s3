variable "bucket_name" {
  type        = string
  description = "The name of the S3 bucket"
}

variable "allowed_ips" {
  type        = list(string)
  description = "The list of allowed IPs"
}

variable "tags" {
  type        = map(string)
  description = "The tags to apply to the S3 bucket"
  default     = {}
}

variable "force_destroy" {
  type        = bool
  description = "Whether all objects should be deleted from the bucket so that the bucket can be destroyed without error. These objects are not recoverable."
  default     = false
}
