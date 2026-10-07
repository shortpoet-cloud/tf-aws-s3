# bucket_baseline

Ownership, public-access block, versioning and default encryption for an existing bucket. ACLs are always disabled and public ACLs always blocked; `allow_public_policy` admits a public bucket policy for website buckets.

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

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_s3_bucket_ownership_controls.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_public_access_block.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_allow_public_policy"></a> [allow\_public\_policy](#input\_allow\_public\_policy) | Allow a public bucket policy (a website bucket). Public ACLs stay blocked either way. | `bool` | `false` | no |
| <a name="input_bucket"></a> [bucket](#input\_bucket) | Name of the bucket this baseline applies to. | `string` | n/a | yes |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | ARN of a KMS key for SSE-KMS. Empty selects SSE-S3 (AES256). | `string` | `""` | no |
| <a name="input_versioning_enabled"></a> [versioning\_enabled](#input\_versioning\_enabled) | Enable versioning. False leaves a never-versioned bucket unversioned (Disabled). | `bool` | `true` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_allow_public_policy"></a> [allow\_public\_policy](#output\_allow\_public\_policy) | Whether a public bucket policy is allowed. Public ACLs are always blocked. |
| <a name="output_sse_algorithm"></a> [sse\_algorithm](#output\_sse\_algorithm) | The default server-side encryption algorithm applied to the bucket. |
| <a name="output_versioning_enabled"></a> [versioning\_enabled](#output\_versioning\_enabled) | Whether versioning is enabled. |
<!-- END_TF_DOCS -->
