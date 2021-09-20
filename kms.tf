
## Bacukps Bucket key
resource "aws_kms_key" "bucket" {
  description             = format("%s Bacukps Bucket Encryption key", module.labels.id)
  deletion_window_in_days = 30
  policy                  = data.aws_iam_policy_document.bucket_kms_policy.json
  tags                    = module.labels.tags
  lifecycle {
    prevent_destroy = true
  }

}

## Bacukps Bucket Key Alias
resource "aws_kms_alias" "bucket" {
  name          = "alias/${module.labels.id}"
  target_key_id = aws_kms_key.bucket.key_id
}

## Bacukps Bucket Key Policy
data "aws_iam_policy_document" "bucket_kms_policy" {
  statement {
    sid     = "Enable IAM User Permissions"
    effect  = "Allow"
    actions = ["kms:*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.aws_account_id}:root"]
    }

    resources = ["*"]
  }

  statement {
    sid     = "Allow alias creation during setup"
    effect  = "Allow"
    actions = ["kms:CreateAlias"]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["ec2.${var.aws_region}.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "kms:CallerAccount"
      values   = [var.aws_account_id]
    }

    resources = ["*"]
  }

}
