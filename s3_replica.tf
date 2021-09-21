## Locals
locals {
  replica_bucket_id = format("%s-replica", module.bucket.s3_bucket_id)
}

## Bucket
module "bucket_replica" {
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

  tags = merge(
    module.labels.tags,
    tomap({ "Name" = local.replica_bucket_id })
  )

}
