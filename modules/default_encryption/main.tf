terraform {
  required_version = ">= 1.5.1"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

locals {
  kms_key_given = var.kms_key_arn != ""
  sse_algorithm = local.kms_key_given ? "aws:kms" : "AES256"
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
