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
  description = "The list of allowed IPs"
}

variable "allowed_user_ids" {
  type        = list(string)
  description = "The list of allowed user ids"
}

variable "owner_id" {
  type        = string
  description = "The owner id. Conflicts with acl."
  default     = ""
}

variable "object_ownership" {
  type        = string
  description = <<EOF
    (Required) Object ownership. Valid values: BucketOwnerPreferred, ObjectWriter or BucketOwnerEnforced
    BucketOwnerPreferred - Objects uploaded to the bucket change ownership to the bucket owner if the objects are uploaded with the bucket-owner-full-control canned ACL.
    ObjectWriter - Uploading account will own the object if the object is uploaded with the bucket-owner-full-control canned ACL.
    BucketOwnerEnforced - Bucket owner automatically owns and has full control over every object in the bucket. ACLs no longer affect permissions to data in the S3 bucket.
  EOF
  default     = "BucketOwnerEnforced"
}

variable "block_public_acls" {
  type        = bool
  description = <<EOF
    (Optional) Whether Amazon S3 should block public ACLs for this bucket. Defaults to false. 
      Enabling this setting does not affect existing policies or ACLs. When set to true causes the following behavior:
        PUT Bucket acl and PUT Object acl calls will fail if the specified ACL allows public access.
        PUT Object calls will fail if the request includes an object ACL.
  EOF
  default     = false
}

variable "block_public_policy" {
  type        = bool
  description = <<EOF
    (Optional) Whether Amazon S3 should block public bucket policies for this bucket. Defaults to false. 
      Enabling this setting does not affect the existing bucket policy. When set to true causes Amazon S3 to:
        Reject calls to PUT Bucket policy if the specified bucket policy allows public access.
  EOF  
  default     = false
}

variable "ignore_public_acls" {
  type        = bool
  description = <<EOF
    (Optional) Whether Amazon S3 should ignore public ACLs for this bucket. Defaults to false. 
      Enabling this setting does not affect the persistence of any existing ACLs and doesn't prevent new public ACLs from being set. 
      When set to true causes Amazon S3 to:
        Ignore public ACLs on this bucket and any objects that it contains.
  EOF
  default     = false
}

variable "restrict_public_buckets" {
  type        = bool
  description = <<EOF
    (Optional) Whether Amazon S3 should restrict public bucket policies for this bucket. Defaults to false. 
      Enabling this setting does not affect the previously stored bucket policy, 
      except that public and cross-account access within the public bucket policy, 
      including non-public delegation to specific accounts, is blocked. When set to true:
        Only the bucket owner and AWS Services can access this buckets if it has a public policy.
  EOF
  default     = false
}

variable "versioning_enabled" {
  type        = bool
  description = <<EOF
    The versioning_configuration configuration block supports the following arguments:
      status - (Required) Versioning state of the bucket. Valid values: Enabled, Suspended, or Disabled. 
        Disabled should only be used when creating or importing resources that correspond to unversioned S3 buckets.
      mfa_delete - (Optional) Specifies whether MFA delete is enabled in the bucket versioning configuration. 
        Valid values: Enabled or Disabled.
  EOF
  default     = true
}

variable "kms_key_arn" {
  type        = string
  description = "The ARN of the KMS key to use when encrypting objects in the bucket. If not provided, S3 will use AES-256 server-side encryption."
  default     = ""
}

variable "acl" {
  type        = string
  description = <<EOF
    (Optional) The canned ACL to apply. Defaults to "private". 
      Conflicts with grant (owner_id). 
      Valid values are private, public-read, public-read-write, aws-exec-read, authenticated-read, bucket-owner-read, 
      bucket-owner-full-control and log-delivery-write.
  EOF
  default     = "private"
  validation {
    condition = contains([
      "private", "public-read", "public-read-write", "aws-exec-read", "authenticated-read",
      "bucket-owner-read", "bucket-owner-full-control", "log-delivery-write", ""
    ], var.acl)
    error_message = "Invalid ACL"
  }
}

variable "force_destroy" {
  type        = bool
  description = "Whether all objects should be deleted from the bucket so that the bucket can be destroyed without error. These objects are not recoverable."
  default     = false
}
