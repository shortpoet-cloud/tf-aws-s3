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

data "publicip_address" "source_v6" {
  source_ip = "::"
}

data "publicip_address" "source_v4" {
  source_ip = "0.0.0.0"
}
provider "aws" {
  profile = "terraform-admin"
}

resource "random_pet" "mad_science" {
  keepers = { name = var.bucket_name }
}

# data "cloudflare_ip_ranges" "cloudflare" {}
data "aws_canonical_user_id" "current" {}
# data "aws_caller_identity" "current" {}
data "aws_iam_role" "terraform_admin" {
  name = "terraform-admin"
}
data "aws_iam_user" "admin" {
  user_name = "Administrator"
}
locals {
  # caller_arn           = "arn:aws:iam::${data.aws_caller_identity.current.account_id}"
}


locals {
  bucket_name = "${var.bucket_name}-${random_pet.mad_science.id}"
  allowed_ips = [
    data.publicip_address.source_v4.ip,
    data.publicip_address.source_v6.ip,
  ]
  # allowed_ips = var.allowed_ips
  # cloudflare_ip_ranges = concat(data.cloudflare_ip_ranges.cloudflare.ipv4_cidr_blocks, data.cloudflare_ip_ranges.cloudflare.ipv6_cidr_blocks)
  owner_id = data.aws_canonical_user_id.current.id
  allowed_user_ids = [
    data.aws_iam_user.admin.user_id,
    "${data.aws_iam_role.terraform_admin.unique_id}:*",
  ]
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
  object_ownership        = "ObjectWriter"

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

  tags = local.tags

}
