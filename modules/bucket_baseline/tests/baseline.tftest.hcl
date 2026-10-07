mock_provider "aws" {}

variables {
  bucket = "example-bucket"
}

run "private_versioned_sse_s3_by_default" {
  command = plan

  assert {
    condition     = one(one(aws_s3_bucket_server_side_encryption_configuration.this.rule).apply_server_side_encryption_by_default).sse_algorithm == "AES256"
    error_message = "Without a KMS key the bucket must default to SSE-S3 (AES256)."
  }

  assert {
    condition     = one(aws_s3_bucket_ownership_controls.this.rule).object_ownership == "BucketOwnerEnforced"
    error_message = "Ownership must be BucketOwnerEnforced (ACLs disabled)."
  }

  assert {
    condition = alltrue([
      aws_s3_bucket_public_access_block.this.block_public_acls,
      aws_s3_bucket_public_access_block.this.ignore_public_acls,
      aws_s3_bucket_public_access_block.this.block_public_policy,
      aws_s3_bucket_public_access_block.this.restrict_public_buckets,
    ])
    error_message = "All public access must be blocked by default."
  }

  assert {
    condition     = one(aws_s3_bucket_versioning.this.versioning_configuration).status == "Enabled"
    error_message = "Versioning must be enabled by default."
  }
}

run "sse_kms_with_kms_key" {
  command = plan

  variables {
    kms_key_arn = "arn:aws:kms:us-east-1:111122223333:key/00000000-0000-0000-0000-000000000000"
  }

  assert {
    condition     = one(one(aws_s3_bucket_server_side_encryption_configuration.this.rule).apply_server_side_encryption_by_default).sse_algorithm == "aws:kms"
    error_message = "With a KMS key the bucket must default to SSE-KMS."
  }

  assert {
    condition     = one(one(aws_s3_bucket_server_side_encryption_configuration.this.rule).apply_server_side_encryption_by_default).kms_master_key_id == var.kms_key_arn
    error_message = "SSE-KMS must use the given key."
  }
}

run "website_allows_a_public_policy_but_never_public_acls" {
  command = plan

  variables {
    allow_public_policy = true
    versioning_enabled  = false
  }

  assert {
    condition = (
      aws_s3_bucket_public_access_block.this.block_public_acls
      && aws_s3_bucket_public_access_block.this.ignore_public_acls
      && !aws_s3_bucket_public_access_block.this.block_public_policy
      && !aws_s3_bucket_public_access_block.this.restrict_public_buckets
    )
    error_message = "A website bucket may hold a public policy; public ACLs stay blocked."
  }

  assert {
    condition     = one(aws_s3_bucket_versioning.this.versioning_configuration).status == "Disabled"
    error_message = "versioning_enabled = false must leave the bucket unversioned."
  }
}
