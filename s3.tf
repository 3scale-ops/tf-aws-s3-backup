## Label
module "labels" {
  source      = "git@github.com:3scale-ops/tf-aws-label.git?ref=tags/0.1.2"
  project     = var.project
  environment = var.environment
  workload    = var.workload
  type        = "s3"
  tf_config   = var.tf_config
}

## Bucket
module "bucket" {
  source    = "terraform-aws-modules/s3-bucket/aws"
  providers = { aws = aws.master }

  bucket = format("3scale-%s-%s-%s",
    var.environment, var.project, var.workload,
  )

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
        kms_master_key_id = aws_kms_key.bucket.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  lifecycle_rule = local.backup_lifecycle_rules

  tags = module.labels.tags

}
