output "bucket_name" {
  description = "Name of the backup bucket."
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "ARN of the backup bucket."
  value       = aws_s3_bucket.this.arn
}

output "tenant_prefixes" {
  description = "Key prefix owned by each tenant."
  value       = local.tenant_prefixes
}

output "writer_role_arns" {
  description = "Put-only writer role ARN per tenant."
  value       = { for tenant, role in module.writer_role : tenant => role.arn }
}

output "restore_role_arns" {
  description = "Read-only restore role ARN per tenant."
  value       = { for tenant, role in module.restore_role : tenant => role.arn }
}

output "break_glass_user_arns" {
  description = "Break-glass IAM user ARN per tenant. No access key is created."
  value       = { for tenant, user in module.break_glass : tenant => user.arn }
}
