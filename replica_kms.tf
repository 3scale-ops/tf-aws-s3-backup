# ------------------------------------------------------------------------------
# Replica Bucket KMS
# ------------------------------------------------------------------------------

## Replica bucket KMS key ------------------------------------------------------
resource "aws_kms_key" "replica" {
  provider = aws.replica

  description = format("%s Replica Bucket Encryption key", module.labels.id)
  policy      = data.aws_iam_policy_document.kms_replica.json

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

## Replica bucket KMS key alias ------------------------------------------------
resource "aws_kms_alias" "replica" {
  provider = aws.replica

  name          = format("alias/%s", local.replica_bucket_id)
  target_key_id = aws_kms_key.replica.key_id
}

## Replica bucket KMS key policy -----------------------------------------------
data "aws_iam_policy_document" "kms_replica" {

  statement {
    sid       = "Enable IAM User Permissions"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.replica.account_id}:root"]
    }

  }

  statement {
    sid       = "Allow alias creation during setup"
    effect    = "Allow"
    actions   = ["kms:CreateAlias"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["ec2.${data.aws_region.replica.name}.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "kms:CallerAccount"
      values   = [data.aws_caller_identity.replica.account_id]
    }

  }

  statement {

    sid       = "Enable Cross Account Encrypt access for S3 Replication"
    effect    = "Allow"
    actions   = ["kms:Encrypt"]
    resources = ["*"]

    principals {
      type = "AWS"
      identifiers = [
        aws_iam_role.replication.arn
      ]
    }

  }

}
