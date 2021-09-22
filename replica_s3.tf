# ------------------------------------------------------------------------------
# Replica Bucket
# ------------------------------------------------------------------------------

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

  lifecycle_rule = local.common_lifecycle_rules

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
    tomap({ "Name" = local.replica_bucket_id })
  )
}
