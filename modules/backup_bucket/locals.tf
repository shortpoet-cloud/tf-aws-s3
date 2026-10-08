locals {
  # The partition comes from the trusted role's ARN, so the module needs no
  # data sources and every policy document is known at plan time.
  partition = regex("^arn:(aws[a-z-]*):", var.identity_center_role_arn)[0]

  bucket_arn      = "arn:${local.partition}:s3:::${var.bucket_name}"
  tenant_prefixes = { for tenant in var.tenants : tenant => "${tenant}/" }
  kms_key_given   = var.kms_key_arn != ""

  # SSE-KMS needs key access scoped to the tenant's objects, and only through S3.
  # GenerateDataKey encrypts a put; Decrypt serves multipart completion and reads.
  tenant_kms_condition = {
    for tenant, prefix in local.tenant_prefixes : tenant => {
      StringLike = {
        "kms:ViaService"                   = "s3.*.amazonaws.com"
        "kms:EncryptionContext:aws:s3:arn" = "${local.bucket_arn}/${prefix}*"
      }
    }
  }
  writer_kms_statements = {
    for tenant in var.tenants : tenant => local.kms_key_given ? [{
      Sid       = "EncryptTenantObjects"
      Effect    = "Allow"
      Action    = ["kms:GenerateDataKey", "kms:Decrypt"]
      Resource  = [var.kms_key_arn]
      Condition = local.tenant_kms_condition[tenant]
    }] : []
  }
  restore_kms_statements = {
    for tenant in var.tenants : tenant => local.kms_key_given ? [{
      Sid       = "DecryptTenantObjects"
      Effect    = "Allow"
      Action    = ["kms:Decrypt"]
      Resource  = [var.kms_key_arn]
      Condition = local.tenant_kms_condition[tenant]
    }] : []
  }

  writer_policies = {
    for tenant, prefix in local.tenant_prefixes : tenant => {
      Version = "2012-10-17"
      Statement = concat([{
        Sid      = "PutUnderTenantPrefix"
        Effect   = "Allow"
        Action   = ["s3:PutObject"]
        Resource = ["${local.bucket_arn}/${prefix}*"]
      }], local.writer_kms_statements[tenant])
    }
  }

  restore_policies = {
    for tenant, prefix in local.tenant_prefixes : tenant => {
      Version = "2012-10-17"
      Statement = concat([
        {
          Sid       = "ListTenantPrefix"
          Effect    = "Allow"
          Action    = ["s3:ListBucket", "s3:ListBucketVersions"]
          Resource  = [local.bucket_arn]
          Condition = { StringLike = { "s3:prefix" = ["${prefix}*"] } }
        },
        {
          Sid      = "ReadTenantObjects"
          Effect   = "Allow"
          Action   = ["s3:GetObject", "s3:GetObjectVersion"]
          Resource = ["${local.bucket_arn}/${prefix}*"]
        },
      ], local.restore_kms_statements[tenant])
    }
  }

  bucket_policy = {
    Version = "2012-10-17"
    Statement = [{
      Sid       = "EnforceTlsRequestsOnly"
      Effect    = "Deny"
      Principal = { AWS = "*" }
      Action    = "s3:*"
      Resource  = [local.bucket_arn, "${local.bucket_arn}/*"]
      Condition = { Bool = { "aws:SecureTransport" = "false" } }
    }]
  }
}
