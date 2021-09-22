# ------------------------------------------------------------------------------
# Master Bucket
# ------------------------------------------------------------------------------

module "master" {
  source    = "terraform-aws-modules/s3-bucket/aws"
  providers = { aws = aws.master }

  bucket = local.master_bucket_id

  acl                     = "private"
  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true
  force_destroy           = var.prevent_destroy ? false : true

  versioning = {
    enabled = true
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

  lifecycle_rule = local.common_lifecycle_rules

  replication_configuration = local.replication_configuration

  tags = merge(
    module.labels.tags,
    tomap({ "Name" = local.master_bucket_id })
  )
}
