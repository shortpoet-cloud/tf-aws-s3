# tf-aws-s3

The root module is a general S3 bucket with an IP- and user-conditioned bucket policy. Submodules:

- [`modules/bucket_baseline`](modules/bucket_baseline): ownership (`BucketOwnerEnforced`, ACLs disabled), public-access block, versioning and default encryption (SSE-KMS when a key ARN is given, SSE-S3 otherwise) for an existing bucket. The root module, `backup_bucket` and `tf-aws-website` all apply it.
- [`modules/backup_bucket`](modules/backup_bucket): a private, versioned credential-backup bucket with per-tenant writer, restore and break-glass access, built on `tf-iam`'s `identity_center_role` and `break_glass_user`.

Releases are semver tags; pin `?ref=vX.Y.Z`. `mise run check` (config in the `sp-cloud` workspace root) runs fmt, validate, tflint and `terraform test`.
