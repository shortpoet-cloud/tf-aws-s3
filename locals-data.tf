data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_region" "current" {}

locals {

  account_id  = data.aws_caller_identity.current.account_id
  partition   = data.aws_partition.current.partition
  region      = data.aws_region.current.name
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
  # TODO verify if needed
  allow_mulitpart_uploads = {
    Sid    = "AllowMulitpartUploads"
    Effect = "Allow"
    Action = [
      "s3:AbortMultipartUpload",
      "s3:DeleteObject",
      "s3:DeleteObjectVersion",
      "s3:GetObject",
      "s3:GetObjectAcl",
      "s3:GetObjectVersion",
      "s3:GetObjectVersionAcl",
      "s3:ListMultipartUploadParts",
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:PutObjectVersionAcl",
    ]
  }
  restrict_to_allowed_ips_ids = {
    Sid    = "RestrictToAllowedIPs&IDs"
    Effect = "Deny"
    Action = "s3:*"
    Resource = [
      aws_s3_bucket.s3.arn,
      "${aws_s3_bucket.s3.arn}/*",
    ]
    Principal = {
      AWS = "*"
    }
    # NotPrincipal = {
    #   AWS = [
    #     "${local.caller_arn}:root",
    #     "${local.caller_arn}:user/Administrator",
    #   ]
    # }
    Condition = {
      NotIpAddress = {
        "aws:SourceIp" = local.allowed_ips
      },
      StringNotLike = {
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
