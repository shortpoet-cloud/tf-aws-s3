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
    Sid       = "PublicReadGetObject"
    Effect    = "Allow"
    Principal = "*"
    Action    = "s3:GetObject"
    Resource = [
      "${aws_s3_bucket.s3.arn}/*",
    ],
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
  restrict_to_allowed_ips_ids = {
    Sid    = "RestrictToAllowedIPs&IDs"
    Effect = "Deny"
    Action = "s3:*"
    Resource = [
      aws_s3_bucket.s3.arn,
      "${aws_s3_bucket.s3.arn}/*",
    ]
    # NotPrincipal = {
    #   AWS = [
    #     "${local.caller_arn}:root",
    #     "${local.caller_arn}:user/Administrator",
    #   ]
    # }
    Principal = "*"
    Condition = {
      NotIpAddress = {
        "aws:SourceIp" = local.allowed_ips
      },
      StringNotLike = {
        "aws:userId" = local.allowed_user_ids
      }
    }
  }

}
data "aws_iam_policy_document" "prevent_unencrypted_uploads" {

  statement {
    sid = "DenyIncorrectEncryptionHeader"

    effect = "Deny"

    principals {
      identifiers = ["*"]
      type        = "AWS"
    }

    actions = [
      "s3:PutObject"
    ]

    resources = [
      "arn:${local.partition}:s3:::${local.bucket_name}/*",
    ]

    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption"

      values = [
        "AES256",
        "aws:kms"
      ]
    }
  }

  statement {
    sid = "DenyUnEncryptedObjectUploads"

    effect = "Deny"

    principals {
      identifiers = ["*"]
      type        = "AWS"
    }

    actions = [
      "s3:PutObject"
    ]

    resources = [
      "arn:${local.partition}:s3:::${local.bucket_name}/*",
    ]

    condition {
      test     = "Null"
      variable = "s3:x-amz-server-side-encryption"

      values = [
        "true"
      ]
    }
  }

  statement {
    sid = "EnforceTlsRequestsOnly"

    effect = "Deny"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = ["s3:*"]

    resources = [
      "arn:${local.partition}:s3:::${local.bucket_name}",
      "arn:${local.partition}:s3:::${local.bucket_name}/*",
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}
