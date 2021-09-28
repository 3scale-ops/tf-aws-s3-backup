# ------------------------------------------------------------------------------
# Replica Bucket KMS
# ------------------------------------------------------------------------------

# Master Bucket key ------------------------------------------------------------
resource "aws_kms_key" "master" {
  provider = aws.master

  description = format("%s primary bucket encryption key", module.labels.id)
  policy      = data.aws_iam_policy_document.master_kms.json

  deletion_window_in_days = 30

  # https://github.com/hashicorp/terraform/issues/3116
  # lifecycle {
  #   prevent_destroy = var.prevent_destroy
  # }

  tags = merge(
    module.labels.tags,
    tomap({ "Name" = local.replica_bucket_id })
  )
}

# Master Bucket key Alias ------------------------------------------------------
resource "aws_kms_alias" "master" {
  provider      = aws.master
  name          = format("alias/%s", local.master_bucket_id)
  target_key_id = aws_kms_key.master.key_id
}

## Master Bucket Key Policy ----------------------------------------------------
data "aws_iam_policy_document" "master_kms" {

  statement {
    sid     = "Enable IAM User Permissions"
    effect  = "Allow"
    actions = ["kms:*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.master.account_id}:root"]
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
      values   = ["ec2.${data.aws_region.master.name}.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "kms:CallerAccount"
      values   = [data.aws_caller_identity.master.account_id]
    }

    resources = ["*"]
  }

}
