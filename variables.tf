variable "bucket_name_prefix" {
  type        = string
  default     = "3scale"
  description = "Bucket name prefix, as S3 bucket ids should be unique."
}

variable "environment" {
  type        = string
  default     = ""
  description = "Environment (dev/stg/pro)"
}

variable "project" {
  type        = string
  default     = ""
  description = "Project (eng/saas)"
}

variable "workload" {
  type        = string
  default     = "backup"
  description = "Workload"
}

variable "tf_config" {
  type        = string
  default     = ""
  description = "Terraform configuration name"
}
