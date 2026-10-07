mock_provider "aws" {}

variables {
  bucket_name              = "credential-backup-111122223333"
  name                     = "credential-backup"
  tenants                  = ["alpha", "beta"]
  identity_center_role_arn = "arn:aws:iam::111122223333:role/aws-reserved/sso.amazonaws.com/us-east-1/AWSReservedSSO_CredentialBackup_0123456789abcdef"
}

run "bucket_protections" {
  command = plan

  # Ownership, public-access blocks and versioning are bucket_baseline's,
  # tested there; this checks the backup bucket takes the private, versioned defaults.
  assert {
    condition     = module.bucket_baseline.versioning_enabled && !module.bucket_baseline.allow_public_policy
    error_message = "The backup bucket must be versioned and fully private."
  }

  assert {
    condition     = aws_s3_bucket.this.force_destroy == false
    error_message = "force_destroy must stay off."
  }

  assert {
    condition     = aws_s3_bucket.this.object_lock_enabled == false
    error_message = "Object Lock stays off; enabling it is the owner's retention decision."
  }

  assert {
    condition = anytrue([
      for statement in jsondecode(aws_s3_bucket_policy.this.policy).Statement :
      statement.Effect == "Deny" && statement.Condition.Bool["aws:SecureTransport"] == "false"
    ])
    error_message = "The bucket policy must deny requests without TLS."
  }
}

run "encryption_sse_s3_by_default" {
  command = plan

  assert {
    condition     = module.bucket_baseline.sse_algorithm == "AES256"
    error_message = "Without a KMS key the bucket must use SSE-S3."
  }

  assert {
    condition     = alltrue([for tenant in var.tenants : length(jsondecode(aws_iam_policy.writer[tenant].policy).Statement) == 1])
    error_message = "Without a KMS key the writer policy carries no KMS statement."
  }
}

run "encryption_sse_kms_with_key" {
  command = plan

  variables {
    kms_key_arn = "arn:aws:kms:us-east-1:111122223333:key/00000000-0000-0000-0000-000000000000"
  }

  assert {
    condition     = module.bucket_baseline.sse_algorithm == "aws:kms"
    error_message = "With a KMS key the bucket must use SSE-KMS."
  }

  assert {
    condition = alltrue(flatten([
      for tenant in var.tenants : [
        for statement in jsondecode(aws_iam_policy.restore[tenant].policy).Statement :
        statement.Condition.StringLike["kms:EncryptionContext:aws:s3:arn"] == "arn:aws:s3:::${var.bucket_name}/${tenant}/*"
        if startswith(statement.Action[0], "kms:")
      ]
    ]))
    error_message = "KMS access must be scoped to the tenant's own objects."
  }
}
