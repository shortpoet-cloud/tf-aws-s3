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

resource "aws_iam_role" "writer" {
  for_each = local.tenant_prefixes

  name               = "${var.name}-${each.key}-writer"
  assume_role_policy = jsonencode(local.identity_center_trust_policy)
  tags               = var.tags
}

resource "aws_iam_role" "restore" {
  for_each = local.tenant_prefixes

  name               = "${var.name}-${each.key}-restore"
  assume_role_policy = jsonencode(local.identity_center_trust_policy)
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "writer" {
  for_each = local.tenant_prefixes

  role       = aws_iam_role.writer[each.key].name
  policy_arn = aws_iam_policy.writer[each.key].arn
}

resource "aws_iam_role_policy_attachment" "restore" {
  for_each = local.tenant_prefixes

  role       = aws_iam_role.restore[each.key].name
  policy_arn = aws_iam_policy.restore[each.key].arn
}

# Break-glass: holds only the restore policy, which is also its permissions
# boundary, so a later attachment cannot widen it. Terraform never creates its
# access key (aws_iam_access_key would put the secret in state); the operator
# creates one out of band and keeps it offline.
resource "aws_iam_user" "break_glass" {
  for_each = local.tenant_prefixes

  name                 = "${var.name}-${each.key}-break-glass"
  permissions_boundary = aws_iam_policy.restore[each.key].arn
  tags                 = var.tags
}

resource "aws_iam_user_policy_attachment" "break_glass" {
  for_each = local.tenant_prefixes

  user       = aws_iam_user.break_glass[each.key].name
  policy_arn = aws_iam_policy.restore[each.key].arn
}
