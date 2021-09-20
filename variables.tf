variable "aws_region" {
  type        = string
  default     = ""
  description = "AWS Region"
}

variable "aws_account_id" {
  type        = string
  default     = ""
  description = "AWS Account ID"
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
  default     = ""
  description = "Workload"
}

variable "tf_config" {
  type        = string
  default     = ""
  description = "Terraform configuration name"
}
