output "s3_bucket_id" {
  value = module.bucket.s3_bucket_id
}

output "s3_bucket_arn" {
  value = module.bucket.s3_bucket_arn
}

output "kms_bucket_key_id" {
  value       = aws_kms_key.bucket.key_id
  description = "The KMS bucket key id."
}
