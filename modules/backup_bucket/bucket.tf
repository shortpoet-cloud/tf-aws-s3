resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name

  # History is the point of this bucket: it is never emptied for a destroy.
  # Object Lock stays off; enabling it later is the owner's retention decision.
  force_destroy       = false
  object_lock_enabled = false

  tags = var.tags

  lifecycle {
    prevent_destroy = true
  }
}

module "bucket_baseline" {
  source = "../bucket_baseline"

  bucket      = aws_s3_bucket.this.id
  kms_key_arn = var.kms_key_arn
}

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id
  policy = jsonencode(local.bucket_policy)

  depends_on = [module.bucket_baseline]
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  # The writer holds s3:PutObject but not s3:AbortMultipartUpload, so without
  # this rule a failed multipart upload's parts stay billed until an admin removes them.
  rule {
    id     = local.abort_incomplete_multipart_uploads_rule_id
    status = "Enabled"

    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  dynamic "rule" {
    for_each = var.noncurrent_version_retention

    content {
      id     = rule.key
      status = "Enabled"

      filter {
        prefix = rule.value.prefix
      }

      noncurrent_version_expiration {
        noncurrent_days           = rule.value.noncurrent_days
        newer_noncurrent_versions = rule.value.newer_noncurrent_versions
      }
    }
  }

  # Noncurrent-version rules act only on a versioned bucket.
  depends_on = [module.bucket_baseline]
}
