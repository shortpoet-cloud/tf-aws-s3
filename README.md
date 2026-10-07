# tf-aws-s3

The root module is a general S3 bucket. Submodules:

- [`modules/backup_bucket`](modules/backup_bucket): a private, versioned credential-backup bucket with per-tenant writer, restore and break-glass access.
- [`modules/default_encryption`](modules/default_encryption): default bucket encryption, SSE-KMS when a key ARN is given and SSE-S3 (AES256) otherwise. Used by both.

Releases are semver tags; pin `?ref=vX.Y.Z`. `mise run check` runs the format, validate, lint and test gate.
