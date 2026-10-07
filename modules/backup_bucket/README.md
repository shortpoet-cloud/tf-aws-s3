# backup_bucket

A versioned, private S3 bucket for credential backups, with per-tenant IAM access.

- **Bucket:** versioning on; SSE-S3 by default, SSE-KMS when `kms_key_arn` is set; all public access blocked; `BucketOwnerEnforced` ownership; TLS-only bucket policy; no `force_destroy`; `prevent_destroy`. Object Lock is off; enabling it later is the owner's retention decision.
- **Per tenant** (key prefix `<tenant>/`):
  - **writer** role: `s3:PutObject` under the prefix only. No delete, delete-version, read, list, lifecycle, policy or ACL actions.
  - **restore** role: `s3:ListBucket` conditioned on `s3:prefix` = `<tenant>/*`, plus `s3:GetObject` and `s3:GetObjectVersion` under the prefix.
  - Both roles trust only `identity_center_role_arn`, an IAM Identity Center permission-set role (MFA is enforced at Identity Center sign-in).
  - **break-glass** IAM user: holds only the restore policy, which is also its permissions boundary. The module never creates an access key; the operator creates one out of band and keeps it offline.
- With SSE-KMS, the writer gets `kms:GenerateDataKey` and `kms:Decrypt` (multipart completion), and the restore role `kms:Decrypt`, each only via S3 and only for the tenant's object ARNs.

## Usage

```hcl
module "credential_backup" {
  source = "git::ssh://git@github.com/shortpoet-cloud/tf-aws-s3.git//modules/backup_bucket?ref=v0.1.0"

  bucket_name              = "credential-backup-111122223333"
  name                     = "credential-backup"
  tenants                  = ["personal", "work"]
  identity_center_role_arn = "arn:aws:iam::111122223333:role/aws-reserved/sso.amazonaws.com/us-east-1/AWSReservedSSO_CredentialBackup_0123456789abcdef"
}
```

## Checks

`mise run check` from the repository root runs `fmt -check`, `validate`, `tflint` and `terraform test` (mocked provider; no AWS calls).

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.11 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.100.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_default_encryption"></a> [default\_encryption](#module\_default\_encryption) | ../default_encryption | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_iam_policy.restore](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.writer](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.restore](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.writer](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.restore](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.writer](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_user.break_glass](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_user) | resource |
| [aws_iam_user_policy_attachment.break_glass](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_user_policy_attachment) | resource |
| [aws_s3_bucket.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_ownership_controls.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_versioning.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_bucket_name"></a> [bucket\_name](#input\_bucket\_name) | Globally unique name of the backup bucket. | `string` | n/a | yes |
| <a name="input_identity_center_role_arn"></a> [identity\_center\_role\_arn](#input\_identity\_center\_role\_arn) | ARN of the IAM Identity Center permission-set role that alone may assume the writer and restore roles. | `string` | n/a | yes |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | ARN of a KMS key for SSE-KMS. Empty selects SSE-S3 (AES256). | `string` | `""` | no |
| <a name="input_name"></a> [name](#input\_name) | Prefix for the IAM role, policy and user names (<name>-<tenant>-<purpose>). | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to every taggable resource. | `map(string)` | `{}` | no |
| <a name="input_tenants"></a> [tenants](#input\_tenants) | Tenant ids. Each tenant owns the key prefix <tenant>/ and gets its own writer role, restore role and break-glass user. | `set(string)` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_break_glass_user_arns"></a> [break\_glass\_user\_arns](#output\_break\_glass\_user\_arns) | Break-glass IAM user ARN per tenant. No access key is created. |
| <a name="output_bucket_arn"></a> [bucket\_arn](#output\_bucket\_arn) | ARN of the backup bucket. |
| <a name="output_bucket_name"></a> [bucket\_name](#output\_bucket\_name) | Name of the backup bucket. |
| <a name="output_restore_role_arns"></a> [restore\_role\_arns](#output\_restore\_role\_arns) | Read-only restore role ARN per tenant. |
| <a name="output_tenant_prefixes"></a> [tenant\_prefixes](#output\_tenant\_prefixes) | Key prefix owned by each tenant. |
| <a name="output_writer_role_arns"></a> [writer\_role\_arns](#output\_writer\_role\_arns) | Put-only writer role ARN per tenant. |
<!-- END_TF_DOCS -->
