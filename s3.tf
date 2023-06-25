resource "aws_s3_bucket" "s3" {
  # With account id, this S3 bucket names can be *globally* unique.
  bucket = local.bucket_name

  force_destroy = var.force_destroy
  # Enable versioning so we can see the full revision history of our
  # state files
  # Enable server-side encryption by default

  tags = local.tags
}

resource "aws_s3_bucket_ownership_controls" "s3" {
  bucket = aws_s3_bucket.s3.id

  rule {
    object_ownership = var.object_ownership
  }
}
resource "aws_s3_bucket_server_side_encryption_configuration" "example" {
  bucket = aws_s3_bucket.s3.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.kms_key_arn != "" ? "AES256" : "aws:kms"
      kms_master_key_id = var.kms_key_arn == "" ? null : var.kms_key_arn
    }
  }
}
resource "aws_s3_bucket_versioning" "versioning_example" {
  bucket = aws_s3_bucket.s3.id
  versioning_configuration {
    status = var.versioning_enabled ? "Enabled" : "Disabled"
    # mfa_delete = var.versioning_mfa_delete_enabled ? "Enabled" : "Disabled"
  }
}
resource "aws_s3_bucket_public_access_block" "s3" {
  bucket = aws_s3_bucket_ownership_controls.s3.id

  block_public_acls       = var.block_public_acls
  block_public_policy     = var.block_public_policy
  ignore_public_acls      = var.ignore_public_acls
  restrict_public_buckets = var.restrict_public_buckets
}

resource "aws_s3_bucket_acl" "s3" {
  count  = var.block_public_acls || var.block_public_policy || var.ignore_public_acls || var.restrict_public_buckets ? 0 : 1
  bucket = aws_s3_bucket_ownership_controls.s3.id

  acl = var.owner_id == "" ? var.acl : null

  access_control_policy {
    # grant {
    #   grantee {
    #     type = "Group"
    #     uri  = "http://acs.amazonaws.com/groups/global/AllUsers"
    #   }
    #   permission = "READ"
    # }

    grant {
      grantee {
        id   = var.owner_id
        type = "CanonicalUser"
      }
      permission = "FULL_CONTROL"
    }

    # grant {
    #   grantee {
    #     type = "Group"
    #     uri  = "http://acs.amazonaws.com/groups/s3/LogDelivery"
    #   }
    #   permission = "READ_ACP"
    # }

    owner {
      id = var.owner_id
    }
  }

}

resource "aws_s3_bucket_policy" "s3" {
  bucket = aws_s3_bucket_ownership_controls.s3.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      local.public_read_get_object,
      local.restrict_to_allowed_ips_ids,
      local.deny_incorrect_encryption_header,
      local.deny_unencrypted_object_uploads,
      local.enforce_tls_requests_only
    ]
  })

}
