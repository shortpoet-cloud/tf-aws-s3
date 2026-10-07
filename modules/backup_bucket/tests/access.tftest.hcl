mock_provider "aws" {
  override_resource {
    target          = aws_iam_policy.writer
    override_during = plan
    values = {
      arn = "arn:aws:iam::111122223333:policy/writer"
    }
  }

  override_resource {
    target          = aws_iam_policy.restore
    override_during = plan
    values = {
      arn = "arn:aws:iam::111122223333:policy/restore"
    }
  }
}

# "ab" shares a leading character with "a", so a prefix pattern without the
# trailing slash would leak across tenants.
variables {
  bucket_name              = "credential-backup-111122223333"
  name                     = "credential-backup"
  tenants                  = ["a", "ab", "beta"]
  identity_center_role_arn = "arn:aws:iam::111122223333:role/aws-reserved/sso.amazonaws.com/us-east-1/AWSReservedSSO_CredentialBackup_0123456789abcdef"
}

run "writer_is_put_only" {
  command = plan

  assert {
    condition = alltrue([
      for tenant in var.tenants :
      [for statement in jsondecode(aws_iam_policy.writer[tenant].policy).Statement : statement.Action] == [["s3:PutObject"]]
    ])
    error_message = "The writer may only PutObject: no delete, delete-version, read, list, lifecycle, policy or ACL actions."
  }

  assert {
    condition = alltrue([
      for tenant in var.tenants :
      one(jsondecode(aws_iam_policy.writer[tenant].policy).Statement).Resource == ["arn:aws:s3:::${var.bucket_name}/${tenant}/*"]
    ])
    error_message = "The writer may only put under its own tenant prefix."
  }

  assert {
    condition     = output.tenant_prefixes == { a = "a/", ab = "ab/", beta = "beta/" }
    error_message = "Each tenant's prefix is <tenant>/."
  }
}

run "restore_is_isolated_per_tenant" {
  command = plan

  assert {
    condition = alltrue([
      for tenant in var.tenants :
      [for statement in jsondecode(aws_iam_policy.restore[tenant].policy).Statement : statement.Action] == [["s3:ListBucket"], ["s3:GetObject", "s3:GetObjectVersion"]]
    ])
    error_message = "The restore role may only list, get and get-version."
  }

  # Every object pattern and list prefix granted to one tenant, with its
  # trailing wildcard removed, must not be a prefix of any other tenant's keys. The
  # bucket ARN itself (ListBucket) is covered by the s3:prefix check.
  assert {
    condition = alltrue(flatten([
      for owner in var.tenants : [
        for other in setsubtract(var.tenants, [owner]) : [
          for statement in jsondecode(aws_iam_policy.restore[owner].policy).Statement : concat(
            [for pattern in statement.Resource : !startswith("arn:aws:s3:::${var.bucket_name}/${other}/key", trimsuffix(pattern, "*")) if pattern != "arn:aws:s3:::${var.bucket_name}"],
            [for prefix in try(statement.Condition.StringLike["s3:prefix"], []) : !startswith("${other}/key", trimsuffix(prefix, "*"))],
          )
        ]
      ]
    ]))
    error_message = "A tenant's restore role must be denied list, get and get-version on every other tenant's prefix."
  }

  assert {
    condition = alltrue([
      for tenant in var.tenants :
      jsondecode(aws_iam_policy.restore[tenant].policy).Statement[0].Condition.StringLike["s3:prefix"] == ["${tenant}/*"]
    ])
    error_message = "ListBucket must be conditioned on the tenant's own prefix."
  }
}

run "break_glass_holds_only_restore" {
  command = plan

  assert {
    condition = alltrue([
      for tenant in var.tenants :
      aws_iam_user_policy_attachment.break_glass[tenant].policy_arn == "arn:aws:iam::111122223333:policy/restore"
      && aws_iam_user.break_glass[tenant].permissions_boundary == "arn:aws:iam::111122223333:policy/restore"
    ])
    error_message = "Break-glass must hold the restore policy, bounded by it."
  }

  assert {
    condition = alltrue(flatten([
      for tenant in var.tenants : [
        for statement in jsondecode(aws_iam_policy.restore[tenant].policy).Statement : [
          for action in statement.Action : !can(regex("^s3:(Put|Delete|Restore|Replicate|Abort)", action))
        ]
      ]
    ]))
    error_message = "Break-glass (the restore policy) must not be able to write."
  }
}

run "roles_trust_only_the_identity_center_role" {
  command = plan

  assert {
    condition = alltrue([
      for role in concat(values(aws_iam_role.writer), values(aws_iam_role.restore)) :
      jsondecode(role.assume_role_policy) == {
        Version = "2012-10-17"
        Statement = [{
          Sid       = "IdentityCenterPermissionSetOnly"
          Effect    = "Allow"
          Principal = { AWS = "arn:aws:iam::111122223333:root" }
          Action    = "sts:AssumeRole"
          Condition = { ArnEquals = { "aws:PrincipalArn" = var.identity_center_role_arn } }
        }]
      }
    ])
    error_message = "Writer and restore roles must trust only the Identity Center permission-set role."
  }
}

run "rejects_a_non_identity_center_role" {
  command = plan

  variables {
    identity_center_role_arn = "arn:aws:iam::111122223333:role/terraform-admin"
  }

  expect_failures = [var.identity_center_role_arn]
}

run "rejects_a_wildcard_tenant" {
  command = plan

  variables {
    tenants = ["a*"]
  }

  expect_failures = [var.tenants]
}
