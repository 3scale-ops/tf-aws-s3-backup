## Locals
locals {
  replica_bucket_id = format("%s-replica", module.master.s3_bucket_id)
}

## Bucket
module "replica" {
  source    = "terraform-aws-modules/s3-bucket/aws"
  providers = { aws = aws.replica }

  bucket = local.replica_bucket_id

  acl                     = "private"
  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true
  force_destroy           = false

  versioning = {
    enabled = true
  }

  lifecycle_rule = local.backup_lifecycle_rules

  server_side_encryption_configuration = {
    rule = {
      bucket_key_enabled = true
      apply_server_side_encryption_by_default = {
        kms_master_key_id = aws_kms_key.replica.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  tags = merge(
    module.labels.tags,
    tomap({ "Name" = local.master_bucket_id })
  )
}

## Replica Bucket key
resource "aws_kms_key" "replica" {
  provider                = aws.replica
  description             = format("%s Bacukps Bucket Encryption key", module.labels.id)
  deletion_window_in_days = 30
  policy                  = data.aws_iam_policy_document.kms_replica.json
  tags                    = module.labels.tags
  lifecycle {
    prevent_destroy = true
  }

}

## Replica Bucket Key Alias
resource "aws_kms_alias" "replica" {
  provider      = aws.replica
  name          = "alias/${module.labels.id}"
  target_key_id = aws_kms_key.replica.key_id
}

## Replica Bucket Key Policy
data "aws_iam_policy_document" "kms_replica" {
  statement {
    sid     = "Enable IAM User Permissions"
    effect  = "Allow"
    actions = ["kms:*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.replica.account_id}:root"]
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
      values   = ["ec2.${data.aws_region.replica.name}.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "kms:CallerAccount"
      values   = [data.aws_caller_identity.replica.account_id]
    }

    resources = ["*"]
  }

}
