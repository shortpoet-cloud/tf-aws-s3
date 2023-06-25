resource "aws_s3_bucket" "s3" {
  # With account id, this S3 bucket names can be *globally* unique.
  bucket = local.bucket_name

  acl = "private"
  # TODO - make this a variable and review
  force_destroy = true
  policy        = data.aws_iam_policy_document.prevent_unencrypted_uploads.json
  # Enable versioning so we can see the full revision history of our
  # state files
  versioning {
    enabled = true
  }

  # Enable server-side encryption by default
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = local.tags
}

resource "aws_s3_bucket_ownership_controls" "s3" {
  bucket = aws_s3_bucket.s3.id

  rule {
    object_ownership = var.object_ownership
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

  # acl = "private"
  # acl = "public-read"

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
    ]
  })

}
