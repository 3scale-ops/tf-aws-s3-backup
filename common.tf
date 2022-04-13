# ------------------------------------------------------------------------------
# Resource Labels
# ------------------------------------------------------------------------------
module "labels" {
  source      = "git@github.com:3scale-ops/tf-aws-label.git?ref=tags/0.1.2"
  project     = var.project
  environment = var.environment
  workload    = var.workload
  type        = "s3"
  tf_config   = var.tf_config
}

locals {

  # ------------------------------------------------------------------------------
  # Master Bucket Id
  # ------------------------------------------------------------------------------

  master_bucket_id = format("%s-%s-%s-%s",
    var.bucket_name_prefix, var.environment, var.project, var.workload,
  )

  # ------------------------------------------------------------------------------
  # Replica Bucket Id
  # ------------------------------------------------------------------------------

  replica_bucket_id = format("%s-replica", local.master_bucket_id)

  # ----------------------------------------------------------------------------
  # S3 Lifecycle Rules for both master and replica bucket
  # ----------------------------------------------------------------------------

  common_lifecycle_rules = [
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
      expiration = {
        expired_object_delete_marker = true
      }
      abort_incomplete_multipart_upload_days = 3
    },
    {
      # 1 year Glacier rule
      # For objects tagged with `Retention: Long-term` and `Archive: Glacier`
      # - Removes versions after 24 hours
      # - Moves to Glacier after 48 hours
      # - Expires after 1 year
      id      = "1 year Glacier"
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
      # 1 year rule
      # For objects tagged with `Retention: 1y`
      # - Removes versions after 24 hours
      # - Expires after 1 year
      id      = "1 year"
      enabled = true
      tags = {
        Retention = "1y"
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
      id      = "90 day Glacier"
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
      id      = "90 day"
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
      id      = "30 day"
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
      id      = "7d day"
      enabled = true
      tags = {
        Retention = "7d"
      }
      noncurrent_version_expiration = {
        days = 3
      }
      expiration = {
        days = 7
      }
    },
    {
      # 3d expiration rule
      # For objects tagged with `Retention: 3d`
      # - Expires after 3 days
      id      = "3d day"
      enabled = true
      tags = {
        Retention = "3d"
      }
      noncurrent_version_expiration = {
        days = 1
      }
      expiration = {
        days = 3
      }
    },
    {
      # 24h expiration rule
      # For objects tagged with `Retention: 24h`
      # - Expires after 24 hours
      id      = "24 hours"
      enabled = true
      tags = {
        Retention = "1d"
      }
      noncurrent_version_expiration = {
        days = 1
      }
      expiration = {
        days = 1
      }
    }
  ]

}
