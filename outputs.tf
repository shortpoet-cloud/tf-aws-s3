output "s3_bucket_name" {
  value       = aws_s3_bucket.s3.id
  description = "The NAME of the S3 bucket"
}

output "s3_bucket_arn" {
  value       = aws_s3_bucket.s3.arn
  description = "The ARN of the S3 bucket"
}

output "s3_bucket_region" {
  value       = aws_s3_bucket.s3.region
  description = "The REGION of the S3 bucket"
}

output "s3_bucket_id" {
  description = "Name (id) of the bucket"
  value       = aws_s3_bucket.s3.id
}

# output "s3_website_endpoint" {
#   description = "Bucket endpoint"
#   value       = aws_s3_bucket_website_configuration.s3.website_endpoint
# }

# output "s3_website_domain" {
#   description = "Website endpoint"
#   value       = aws_s3_bucket_website_configuration.s3.website_domain
# }

output "tags" {
  value = aws_s3_bucket.s3.tags
}
