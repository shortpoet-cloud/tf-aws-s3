terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    publicip = {
      source  = "nxt-engineering/publicip"
      version = "0.0.9"
    }
  }
  required_version = ">= 1.5.1"
}

provider "aws" {
  profile = "terraform-admin"
}

data "publicip_address" "source_v6" {
  source_ip = "::"
}

data "publicip_address" "source_v4" {
  source_ip = "0.0.0.0"
}

resource "random_pet" "mad_science" {
  keepers = { name = var.bucket_name }
}

data "aws_canonical_user_id" "current" {}
data "aws_iam_role" "terraform_admin" {
  name = "terraform-admin"
}
data "aws_iam_user" "admin" {
  user_name = "Administrator"
}

locals {
  bucket_name = "${var.bucket_name}-${random_pet.mad_science.id}"
  allowed_ips = [
    data.publicip_address.source_v4.ip,
    data.publicip_address.source_v6.ip,
  ]
  # allowed_ips = var.allowed_ips
  owner_id = data.aws_canonical_user_id.current.id # conflicts with acl
  allowed_user_ids = [
    data.aws_iam_user.admin.user_id,
    "${data.aws_iam_role.terraform_admin.unique_id}:*",
  ]
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
  object_ownership        = "ObjectWriter"
  versioning_enabled      = true
  kms_key_arn             = ""
  acl                     = "" # conflicts with owner_id
  force_destroy           = var.force_destroy

  tags = merge(var.tags, { Type = "Module Example" })
}

module "s3_example" {

  source = "./.."
  # source                  = "git@github.com:shortpoet-cloud/tf-aws-s3.git?ref=main"

  bucket_name             = local.bucket_name
  allowed_ips             = local.allowed_ips
  owner_id                = local.owner_id
  allowed_user_ids        = local.allowed_user_ids
  object_ownership        = local.object_ownership
  block_public_acls       = local.block_public_acls
  block_public_policy     = local.block_public_policy
  ignore_public_acls      = local.ignore_public_acls
  restrict_public_buckets = local.restrict_public_buckets
  versioning_enabled      = local.versioning_enabled
  kms_key_arn             = local.kms_key_arn
  acl                     = local.acl
  force_destroy           = local.force_destroy

  tags = local.tags

}
