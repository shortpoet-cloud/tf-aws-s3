resource "aws_iam_policy" "writer" {
  for_each = local.writer_policies

  name        = "${var.name}-${each.key}-writer"
  description = "Put-only access under ${local.tenant_prefixes[each.key]} in ${var.bucket_name}."
  policy      = jsonencode(each.value)
  tags        = var.tags
}

resource "aws_iam_policy" "restore" {
  for_each = local.restore_policies

  name        = "${var.name}-${each.key}-restore"
  description = "Read-only access under ${local.tenant_prefixes[each.key]} in ${var.bucket_name}."
  policy      = jsonencode(each.value)
  tags        = var.tags
}

module "writer_role" {
  source   = "git::ssh://git@github.com/shortpoet-cloud/tf-iam.git//modules/identity_center_role?ref=v0.1.0-rc.3"
  for_each = local.tenant_prefixes

  name                     = "${var.name}-${each.key}-writer"
  identity_center_role_arn = var.identity_center_role_arn
  policy_arns              = { writer = aws_iam_policy.writer[each.key].arn }
  tags                     = var.tags
}

module "restore_role" {
  source   = "git::ssh://git@github.com/shortpoet-cloud/tf-iam.git//modules/identity_center_role?ref=v0.1.0-rc.3"
  for_each = local.tenant_prefixes

  name                     = "${var.name}-${each.key}-restore"
  identity_center_role_arn = var.identity_center_role_arn
  policy_arns              = { restore = aws_iam_policy.restore[each.key].arn }
  tags                     = var.tags
}

module "break_glass" {
  source   = "git::ssh://git@github.com/shortpoet-cloud/tf-iam.git//modules/break_glass_user?ref=v0.1.0-rc.3"
  for_each = local.tenant_prefixes

  name       = "${var.name}-${each.key}-break-glass"
  policy_arn = aws_iam_policy.restore[each.key].arn
  tags       = var.tags
}
