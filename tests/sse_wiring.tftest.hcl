mock_provider "aws" {}

variables {
  bucket_name      = "example-bucket"
  tags             = {}
  allowed_ips      = []
  allowed_user_ids = []
  # Consumers pass the bucket owner's canonical id, as examples/ and filez do.
  owner_id = "0000000000000000000000000000000000000000000000000000000000000000"
}

run "sse_s3_without_kms_key" {
  command = plan

  assert {
    condition     = module.default_encryption.sse_algorithm == "AES256"
    error_message = "Without a KMS key the bucket must default to SSE-S3 (AES256)."
  }
}

run "sse_kms_with_kms_key" {
  command = plan

  variables {
    kms_key_arn = "arn:aws:kms:us-east-1:111122223333:key/00000000-0000-0000-0000-000000000000"
  }

  assert {
    condition     = module.default_encryption.sse_algorithm == "aws:kms"
    error_message = "With a KMS key the bucket must default to SSE-KMS."
  }
}
