locals {

  # ----------------------------------------------------------------------------
  # S3 Replication Configuration for the master bucket
  # ----------------------------------------------------------------------------

  replication_configuration = {
    role = aws_iam_role.replication.arn

    rules = [
      {
        id       = "90d retention objects"
        status   = "Enabled"
        priority = 10

        source_selection_criteria = {
          sse_kms_encrypted_objects = {
            enabled = true
          }
        }

        filter = {
          tags = {
            Retention = "90d"
          }
        }

        destination = {
          bucket             = module.replica.s3_bucket_arn
          storage_class      = "STANDARD"
          replica_kms_key_id = aws_kms_key.replica.arn
          account_id         = data.aws_caller_identity.replica.account_id
          access_control_translation = {
            owner = "Destination"
          }
        }
      }
    ]
  }
}

