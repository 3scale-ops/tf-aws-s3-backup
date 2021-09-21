output "s3_master_bucket_id" {
  value = module.master.s3_bucket_id
}

output "s3_master_bucket_arn" {
  value = module.master.s3_bucket_arn
}

output "kms_master_bucket_key_id" {
  value       = aws_kms_key.master.key_id
  description = "The KMS bucket key id."
}

output "s3_replica_bucket_id" {
  value = module.replica.s3_bucket_id
}

output "s3_replica_bucket_arn" {
  value = module.replica.s3_bucket_arn
}

output "kms_replica_bucket_key_id" {
  value       = aws_kms_key.replica.key_id
  description = "The KMS bucket key id."
}
