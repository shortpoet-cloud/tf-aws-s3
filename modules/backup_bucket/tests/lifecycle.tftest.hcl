mock_provider "aws" {}

variables {
  bucket_name              = "credential-backup-111122223333"
  name                     = "credential-backup"
  tenants                  = ["alpha", "beta"]
  identity_center_role_arn = "arn:aws:iam::111122223333:role/aws-reserved/sso.amazonaws.com/us-east-1/AWSReservedSSO_CredentialBackup_0123456789abcdef"
}

run "aborts_incomplete_multipart_uploads_and_keeps_every_version_by_default" {
  command = plan

  assert {
    condition     = length(aws_s3_bucket_lifecycle_configuration.this.rule) == 1
    error_message = "Without retention rules the only lifecycle rule is the multipart abort."
  }

  assert {
    condition     = aws_s3_bucket_lifecycle_configuration.this.rule[0].abort_incomplete_multipart_upload[0].days_after_initiation == 7
    error_message = "Incomplete multipart uploads must be aborted after 7 days."
  }

  assert {
    condition     = length(aws_s3_bucket_lifecycle_configuration.this.rule[0].noncurrent_version_expiration) == 0
    error_message = "The multipart abort must not expire any version."
  }
}

run "expires_noncurrent_versions_under_a_tenant_sub_prefix" {
  command = plan

  variables {
    noncurrent_version_retention = {
      alpha-sessions = {
        prefix                    = "alpha/sessions/"
        noncurrent_days           = 30
        newer_noncurrent_versions = 7
      }
    }
  }

  assert {
    condition     = length(aws_s3_bucket_lifecycle_configuration.this.rule) == 2
    error_message = "One retention rule is added beside the multipart abort."
  }

  assert {
    condition = (
      aws_s3_bucket_lifecycle_configuration.this.rule[1].id == "alpha-sessions"
      && aws_s3_bucket_lifecycle_configuration.this.rule[1].filter[0].prefix == "alpha/sessions/"
      && aws_s3_bucket_lifecycle_configuration.this.rule[1].noncurrent_version_expiration[0].noncurrent_days == 30
      && aws_s3_bucket_lifecycle_configuration.this.rule[1].noncurrent_version_expiration[0].newer_noncurrent_versions == 7
    )
    error_message = "The retention rule must carry its id, prefix, noncurrent_days and newer_noncurrent_versions."
  }

  assert {
    condition     = length(aws_s3_bucket_lifecycle_configuration.this.rule[1].expiration) == 0
    error_message = "A retention rule must never expire a current version."
  }
}

run "rejects_a_prefix_outside_every_tenant" {
  command = plan

  variables {
    noncurrent_version_retention = {
      gamma = { prefix = "gamma/", noncurrent_days = 30, newer_noncurrent_versions = 7 }
    }
  }

  expect_failures = [var.noncurrent_version_retention]
}

# Without the slash, "alpha" would also expire tenant "alphabet"'s history.
run "rejects_a_prefix_without_the_tenants_trailing_slash" {
  command = plan

  variables {
    tenants = ["alpha", "alphabet"]
    noncurrent_version_retention = {
      alpha = { prefix = "alpha", noncurrent_days = 30, newer_noncurrent_versions = 7 }
    }
  }

  expect_failures = [var.noncurrent_version_retention]
}

run "rejects_more_than_100_newer_noncurrent_versions" {
  command = plan

  variables {
    noncurrent_version_retention = {
      alpha = { prefix = "alpha/", noncurrent_days = 30, newer_noncurrent_versions = 101 }
    }
  }

  expect_failures = [var.noncurrent_version_retention]
}

run "rejects_zero_noncurrent_days" {
  command = plan

  variables {
    noncurrent_version_retention = {
      alpha = { prefix = "alpha/", noncurrent_days = 0, newer_noncurrent_versions = 7 }
    }
  }

  expect_failures = [var.noncurrent_version_retention]
}

run "rejects_the_multipart_abort_rule_id" {
  command = plan

  variables {
    noncurrent_version_retention = {
      abort-incomplete-multipart-uploads = { prefix = "alpha/", noncurrent_days = 30, newer_noncurrent_versions = 7 }
    }
  }

  expect_failures = [var.noncurrent_version_retention]
}
