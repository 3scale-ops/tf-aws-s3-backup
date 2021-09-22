output "s3_master_bucket_id" {
  value       = module.master.s3_bucket_id
  description = "The master bucket id (bucket name)."
}

output "s3_master_bucket_arn" {
  value       = module.master.s3_bucket_arn
  description = "The master bucket ARN."
}

output "kms_master_bucket_key_id" {
  value       = aws_kms_key.master.key_id
  description = "The master KMS bucket key id."
}

output "s3_replica_bucket_id" {
  value       = module.replica.s3_bucket_id
  description = "The name bucket id (bucket name)."
}

output "s3_replica_bucket_arn" {
  value       = module.replica.s3_bucket_arn
  description = "The replica bucket ARN."
}

output "kms_replica_bucket_key_id" {
  value       = aws_kms_key.replica.key_id
  description = "The replica KMS bucket key id."
}
