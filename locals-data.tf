locals {
  bucket_name = var.bucket_name

  tags = merge(
    var.tags,
    {
      "Name" = var.bucket_name
    }
  )
}


# policy 

locals {
  allowed_ips      = var.allowed_ips
  allowed_user_ids = var.allowed_user_ids

  public_read_get_object = {
    Sid    = "PublicReadGetObject"
    Effect = "Allow"
    Action = "s3:GetObject"
    Resource = [
      "${aws_s3_bucket.s3.arn}/*",
    ],
    Principal = {
      AWS = "*"
    }
    # Condition = {
    #   StringEquals = {
    #     "aws:Referer" = [
    #       "https://${var.site_domain}/*",
    #       "https://${var.site_domain}",
    #     ]
    #   }
    # }
    Condition = {
      IpAddress = {
        "aws:SourceIp" = local.allowed_ips
      }
    }
  }
  allow_s3_list = {
    Sid    = "AllowS3ListGet"
    Effect = "Allow"
    Action = [
      "s3:ListBucket",
    ]
    Resource = [
      aws_s3_bucket.s3.arn,
    ]
    Principal = {
      AWS = "*"
    }
    Condition = {
      StringLike = {
        "aws:userId" = local.allowed_user_ids
      }
    }
  }
  allow_s3_get_object = {
    Sid    = "AllowS3ListGetObject"
    Effect = "Allow"
    Action = [
      "s3:GetObject"
    ]
    Resource = [
      "${aws_s3_bucket.s3.arn}/*",
    ]
    Principal = {
      AWS = "*"
    }
    Condition = {
      StringLike = {
        "aws:userId" = local.allowed_user_ids
      }
    }
  }
  deny_incorrect_encryption_header = {
    Sid    = "DenyIncorrectEncryptionHeader"
    Effect = "Deny"
    Action = "s3:PutObject"
    Resource = [
      "${aws_s3_bucket.s3.arn}/*",
    ]
    Principal = {
      AWS = "*"
    }
    Condition = {
      StringNotEquals = {
        "s3:x-amz-server-side-encryption" = [
          "AES256",
          "aws:kms",
        ]
      }
    }
  }
  deny_unencrypted_object_uploads = {
    Sid    = "DenyUnEncryptedObjectUploads"
    Effect = "Deny"
    Action = "s3:PutObject"
    Resource = [
      "${aws_s3_bucket.s3.arn}/*",
    ]
    Principal = {
      AWS = "*"
    }
    Condition = {
      Null = {
        "s3:x-amz-server-side-encryption" = "true"
      }
    }
  }

  enforce_tls_requests_only = {
    Sid    = "EnforceTlsRequestsOnly"
    Effect = "Deny"
    Action = "s3:*"
    Resource = [
      aws_s3_bucket.s3.arn,
      "${aws_s3_bucket.s3.arn}/*",
    ]
    Principal = {
      AWS = "*"
    }
    Condition = {
      Bool = {
        "aws:SecureTransport" = "false"
      }
    }
  }
}
