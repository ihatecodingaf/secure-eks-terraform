data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

data "aws_iam_policy_document" "this" {
  # In a key policy, Resource "*" means "this key only", so these are false positives.
  #checkov:skip=CKV_AWS_109:Key policy resource "*" refers to this key only
  #checkov:skip=CKV_AWS_111:Key policy resource "*" refers to this key only
  #checkov:skip=CKV_AWS_356:Key policy resource "*" refers to this key only
  # Delegate key administration to IAM in this account. Without this the key
  # could become unmanageable if every principal in the policy were removed.
  statement {
    sid       = "EnableIAMPolicies"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  dynamic "statement" {
    for_each = var.policy_statements

    content {
      sid       = statement.value.sid
      effect    = "Allow"
      actions   = statement.value.actions
      resources = ["*"]

      principals {
        type        = statement.value.principal_type
        identifiers = statement.value.principal_identifiers
      }

      dynamic "condition" {
        for_each = statement.value.conditions

        content {
          test     = condition.value.test
          variable = condition.value.variable
          values   = condition.value.values
        }
      }
    }
  }
}

resource "aws_kms_key" "this" {
  description             = var.description
  deletion_window_in_days = var.deletion_window_in_days
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.this.json
  tags                    = var.tags
}

resource "aws_kms_alias" "this" {
  name          = "alias/${var.alias}"
  target_key_id = aws_kms_key.this.key_id
}
