terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
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
  required_version = ">= 1.11"
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
  allowed_user_ids = [
    data.aws_iam_user.admin.user_id,
    "${data.aws_iam_role.terraform_admin.unique_id}:*",
  ]
  allow_public_policy = true
  versioning_enabled  = true
  kms_key_arn         = ""
  force_destroy       = var.force_destroy

  tags = merge(var.tags, { Type = "Module Example" })
}

module "s3_example" {

  source = "./.."
  # source                  = "git@github.com:shortpoet-cloud/tf-aws-s3.git?ref=main"

  bucket_name         = local.bucket_name
  allowed_ips         = local.allowed_ips
  allowed_user_ids    = local.allowed_user_ids
  allow_public_policy = local.allow_public_policy
  versioning_enabled  = local.versioning_enabled
  kms_key_arn         = local.kms_key_arn
  force_destroy       = local.force_destroy

  tags = local.tags

}
