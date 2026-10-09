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
      [for statement in jsondecode(aws_iam_policy.restore[tenant].policy).Statement : statement.Action] == [["s3:ListBucket", "s3:ListBucketVersions"], ["s3:GetObject", "s3:GetObjectVersion"]]
    ])
    error_message = "The restore role may only list objects, list versions, get and get-version."
  }

  # Every object pattern and list prefix granted to one tenant, with its
  # trailing wildcard removed, must not be a prefix of any other tenant's keys. The
  # bucket ARN itself (ListBucket, ListBucketVersions) is covered by the s3:prefix check.
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
    error_message = "A tenant's restore role must be denied list, list-versions, get and get-version on every other tenant's prefix."
  }

  assert {
    condition = alltrue([
      for tenant in var.tenants :
      jsondecode(aws_iam_policy.restore[tenant].policy).Statement[0].Condition.StringLike["s3:prefix"] == ["${tenant}/*"]
    ])
    error_message = "ListBucket and ListBucketVersions must be conditioned on the tenant's own prefix."
  }
}

# Restore finds an older good copy by listing versions, so that listing must
# stay inside the tenant's prefix like ListBucket does.
run "version_listing_is_isolated_per_tenant" {
  command = plan

  assert {
    condition = alltrue(flatten([
      for owner in var.tenants : [
        for statement in jsondecode(aws_iam_policy.restore[owner].policy).Statement : [
          for other in setsubtract(var.tenants, [owner]) : [
            for prefix in try(statement.Condition.StringLike["s3:prefix"], [""]) : !startswith("${other}/key", trimsuffix(prefix, "*"))
          ]
        ] if contains(statement.Action, "s3:ListBucketVersions")
      ]
    ]))
    error_message = "A tenant's restore role must be denied listing versions under every other tenant's prefix, and never list versions unconditioned."
  }

  assert {
    condition = alltrue([
      for tenant in var.tenants :
      length([for statement in jsondecode(aws_iam_policy.restore[tenant].policy).Statement : statement if contains(statement.Action, "s3:ListBucketVersions")]) == 1
    ])
    error_message = "Each restore role must be able to list its own object versions."
  }
}

run "break_glass_holds_only_restore" {
  command = plan

  # tf-iam's break_glass_user makes its one policy its boundary too.
  assert {
    condition     = alltrue([for tenant in var.tenants : module.break_glass[tenant].policy_arn == "arn:aws:iam::111122223333:policy/restore"])
    error_message = "Break-glass must hold only the restore policy."
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

run "roles_carry_only_their_own_policy" {
  command = plan

  # Trust (Identity Center role only) is tf-iam identity_center_role's, tested there.
  assert {
    condition = alltrue([
      for tenant in var.tenants :
      module.writer_role[tenant].policy_arns == tomap({ writer = "arn:aws:iam::111122223333:policy/writer" })
      && module.restore_role[tenant].policy_arns == tomap({ restore = "arn:aws:iam::111122223333:policy/restore" })
    ])
    error_message = "Each role must carry only its own policy."
  }
}

run "rejects_a_wildcard_tenant" {
  command = plan

  variables {
    tenants = ["a*"]
  }

  expect_failures = [var.tenants]
}
