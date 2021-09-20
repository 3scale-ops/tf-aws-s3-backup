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
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "2.9.0"
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

  lifecycle_rule = [
    {
      # Default rule
      # For objects when no other policy takes precedence
      # * https://docs.aws.amazon.com/AmazonS3/latest/userguide/lifecycle-configuration-examples.html#lifecycle-config-conceptual-ex5
      # - Removes versions after 15 days
      # - Moves to Glacier after 360 days
      # - Never Expire
      id      = "No expiration (Default)"
      enabled = true
      transition = [{
        days          = 360
        storage_class = "GLACIER"
      }]
      noncurrent_version_expiration = {
        days = 15
      }
    },
    {
      # Long-term Glacier rule
      # For objects tagged with `Retention: Long-term` and `Archive: Glacier`
      # - Removes versions after 24 hours
      # - Moves to Glacier after 48 hours
      # - Expires after 1 year
      id      = "1y Glacier"
      enabled = true
      tags = {
        Retention = "1y",
        Archive   = "Glacier"
      }
      transition = [
        {
          days          = 2
          storage_class = "GLACIER"
      }]
      expiration = {
        days = 360
      }
      noncurrent_version_expiration = {
        days = 1
      }
    },
    {
      # 1y rule
      # For objects tagged with `Retention: 1y`
      # - Removes versions after 24 hours
      # - Expires after 1 year
      id      = "1y"
      enabled = true
      tags = {
        Retention = "Long-term"
      }
      expiration = {
        days = 360
      }
      noncurrent_version_expiration = {
        days = 1
      }
    },
    {
      # 90d Glacier expiration rule
      # For objects tagged with `Retention: 90d` and `Archive: Glacier`
      # - Removes versions after 7 days
      # - Moves to Glacier after 7 days
      # - Expires after 90 days in Glacier (97 since creation)
      id      = "90 day Glacier expiration"
      enabled = true
      tags = {
        Retention = "90d"
        Archive   = "Glacier"
      }
      transition = [
        {
          days          = 7
          storage_class = "GLACIER"
      }]
      noncurrent_version_expiration = {
        days = 7
      }
      expiration = {
        days = 97
      }
    },
    {
      # 90d expiration rule
      # For objects tagged with `Retention: 90d`
      # - Removes versions after 7 days
      # - Expires after 97 days (to match 90 day glacier policy)
      id      = "90 day expiration"
      enabled = true
      tags = {
        Retention = "90d"
      }
      noncurrent_version_expiration = {
        days = 7
      }
      expiration = {
        days = 97
      }
    },
    {
      # 30d expiration rule
      # For objects tagged with `Retention: 30d`
      # - Removes versions after 7 days
      # - Expires after 30 days
      id      = "30 day expiration"
      enabled = true
      tags = {
        Retention = "30d"
      }
      noncurrent_version_expiration = {
        days = 7
      }
      expiration = {
        days = 30
      }
    },
    {
      # 7d expiration rule
      # For objects tagged with `Retention: 7d`
      # - Expires after 7 days
      id      = "7d day expiration"
      enabled = true
      tags = {
        Retention = "7d"
      }
      noncurrent_version_expiration = {
        days = 7
      }
      expiration = {
        days = 7
      }
    },
    {
      # 3d expiration rule
      # For objects tagged with `Retention: 3d`
      # - Expires after 3 days
      id      = "3d day expiration"
      enabled = true
      tags = {
        Retention = "3d"
      }
      noncurrent_version_expiration = {
        days = 3
      }
      expiration = {
        days = 3
      }
    }
  ]

  tags = module.labels.tags

}
