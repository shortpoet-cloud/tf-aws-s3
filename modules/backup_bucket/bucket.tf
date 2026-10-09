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
