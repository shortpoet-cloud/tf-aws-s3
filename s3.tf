resource "aws_s3_bucket" "s3" {
  bucket        = local.bucket_name
  force_destroy = var.force_destroy
  tags          = local.tags
}

module "bucket_baseline" {
  source = "./modules/bucket_baseline"

  bucket              = aws_s3_bucket.s3.id
  kms_key_arn         = var.kms_key_arn
  versioning_enabled  = var.versioning_enabled
  allow_public_policy = var.allow_public_policy
}

moved {
  from = aws_s3_bucket_ownership_controls.s3
  to   = module.bucket_baseline.aws_s3_bucket_ownership_controls.this
}

moved {
  from = aws_s3_bucket_public_access_block.s3
  to   = module.bucket_baseline.aws_s3_bucket_public_access_block.this
}

moved {
  from = aws_s3_bucket_versioning.versioning_example
  to   = module.bucket_baseline.aws_s3_bucket_versioning.enabled[0]
}

moved {
  from = aws_s3_bucket_server_side_encryption_configuration.example
  to   = module.bucket_baseline.aws_s3_bucket_server_side_encryption_configuration.this
}

# Ownership is BucketOwnerEnforced, so ACLs no longer apply. The old ACL
# resource also failed with default inputs (acl and access_control_policy
# both set). Forget it without touching the bucket.
removed {
  from = aws_s3_bucket_acl.s3

  lifecycle {
    destroy = false
  }
}

resource "aws_s3_bucket_policy" "s3" {
  bucket = aws_s3_bucket.s3.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      local.public_read_get_object,
      local.deny_incorrect_encryption_header,
      local.deny_unencrypted_object_uploads,
      local.enforce_tls_requests_only,
      local.allow_s3_list,
      local.allow_s3_get_object,
    ]
  })

  depends_on = [module.bucket_baseline]
}
