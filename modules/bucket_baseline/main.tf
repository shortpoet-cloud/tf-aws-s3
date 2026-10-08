terraform {
  required_version = ">= 1.11"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

locals {
  kms_key_given = var.kms_key_arn != ""
  sse_algorithm = local.kms_key_given ? "aws:kms" : "AES256"
}

# ACLs are disabled: the bucket owner owns every object.
resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = var.bucket

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = var.bucket

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = !var.allow_public_policy
  restrict_public_buckets = !var.allow_public_policy
}

# Destroying an Enabled versioning resource suspends versioning on a bucket that
# stays, so the versioned case is guarded. A never-versioned website bucket keeps
# an unguarded Disabled resource, so its teardown still works.
resource "aws_s3_bucket_versioning" "enabled" {
  count  = var.versioning_enabled ? 1 : 0
  bucket = var.bucket

  versioning_configuration {
    status = "Enabled"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "disabled" {
  count  = var.versioning_enabled ? 0 : 1
  bucket = var.bucket

  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = var.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = local.sse_algorithm
      kms_master_key_id = local.kms_key_given ? var.kms_key_arn : null
    }
  }
}
