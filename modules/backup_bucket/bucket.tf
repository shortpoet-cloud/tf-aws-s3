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

resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = "Enabled"
  }
}

module "default_encryption" {
  source = "../default_encryption"

  bucket      = aws_s3_bucket.this.id
  kms_key_arn = var.kms_key_arn
}

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id
  policy = jsonencode(local.bucket_policy)

  depends_on = [aws_s3_bucket_public_access_block.this]
}
