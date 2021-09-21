## Label
module "labels" {
  source      = "git@github.com:3scale-ops/tf-aws-label.git?ref=tags/0.1.2"
  project     = var.project
  environment = var.environment
  workload    = var.workload
  type        = "s3"
  tf_config   = var.tf_config
}

## Locals
locals {
  master_bucket_id = format("3scale-%s-%s-%s",
    var.environment, var.project, var.workload,
  )
}

## Bucket
module "master" {
  source    = "terraform-aws-modules/s3-bucket/aws"
  providers = { aws = aws.master }

  bucket = local.master_bucket_id

  acl                     = "private"
  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true
  force_destroy           = false

  versioning = {
    enabled = false
  }

  server_side_encryption_configuration = {
    rule = {
      bucket_key_enabled = true
      apply_server_side_encryption_by_default = {
        kms_master_key_id = aws_kms_key.master.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  lifecycle_rule = local.backup_lifecycle_rules

  tags = merge(
    module.labels.tags,
    tomap({ "Name" = local.master_bucket_id })
  )
}

## Master Bucket key
resource "aws_kms_key" "master" {
  provider                = aws.master
  description             = format("%s Bacukps Bucket Encryption key", module.labels.id)
  deletion_window_in_days = 30
  policy                  = data.aws_iam_policy_document.master_kms.json
  tags                    = module.labels.tags
  lifecycle {
    prevent_destroy = true
  }

}

## Master Bucket Key Alias
resource "aws_kms_alias" "master" {
  provider      = aws.master
  name          = "alias/${module.labels.id}"
  target_key_id = aws_kms_key.master.key_id
}

## Master Bucket Key Policy
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
