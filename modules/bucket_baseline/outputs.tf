output "sse_algorithm" {
  description = "The default server-side encryption algorithm applied to the bucket."
  value       = local.sse_algorithm
}

output "versioning_enabled" {
  description = "Whether versioning is enabled."
  value       = var.versioning_enabled
}

output "allow_public_policy" {
  description = "Whether a public bucket policy is allowed. Public ACLs are always blocked."
  value       = var.allow_public_policy
}
