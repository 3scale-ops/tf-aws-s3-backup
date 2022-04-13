# tf-aws-s3-backup

[![format-tests](https://github.com/3scale-ops/tf-aws-s3-backup/actions/workflows/format-tests.yaml/badge.svg)](https://github.com/3scale-ops/tf-aws-s3-backup/actions/workflows/format-tests.yaml)
[![release](https://badgen.net/github/release/3scale-ops/tf-aws-s3-backup)](https://github.com/3scale-ops/tf-aws-s3-backup/releases)
[![license](https://badgen.net/github/license/3scale-ops/tf-aws-s3-backup)](https://github.com/3scale-ops/tf-aws-s3-backup/blob/main/LICENSE)

This module creates a bucket for backups with encryption at rest,
retention polices based on tags and cross-account-and-region replication.

- **master bucket** for the master copy of the backups
  - deployed in the main account
  - with bucket encyption using a dedicated AWS KMS key
  - with lifecycle rules based on object tags
  - with replication rules based on object tags
- **replica bucket** for the replica of the backups
  - deployed in the secondary account
  - with bucket encyption using a dedicated AWS KMS key
  - with lifecycle rules based on object tags
- **replication iam role** to
  - read and decrypt the backups from the master bucket using master's key
  - replicate and encrypt the backups to the replica bucket using replica's key

### Lifecycle Rules

| Lifecycle rule name | Scope                                        | Current version transitions | Current version Expiration | Previous version expiration |
| ------------------- | -------------------------------------------- | --------------------------- | -------------------------- | --------------------------- |
| No expiration       | Entire bucket                                | Glacier after 1 year        | Never                      | Deleted after 15 days       |
| 1 year Glacier      | Tags `Archive: Glacier` and `Retention: 1y`  | Glacier after 48 hours      | After 1 year               | Deleted after 24 hours      |
| 1 year              | Tags `Retention: 1y`                         | No transition               | After 1 year               | Deleted after 24 hours      |
| 90 day Glacier      | Tags `Archive: Glacier` and `Retention: 90d` | Glacier after 7 days        | After 97 days              | After 7 days                |
| 90 day              | Tags `Retention: 90d`                        | No transition               | After 97 days              | After 7 days                |
| 30 day              | Tags `Retention: 30d`                        | No transition               | After 30 days              | After 7 days                |
| 7d day              | Tags `Retention: 7d`                         | No transition               | After 7 days               | After 3 days                |
| 3d day              | Tags `Retention: 3d`                         | No transition               | After 3 days               | After 24 hours              |
| 24h hours           | Tags `Retention: 24h`                        | No transition               | After 24 hours             | After 24 hours              |

### Replication Rules

| Replication rule name  | Scope                  | Replica Lifecycle                                                         |
| ---------------------- | ---------------------- | ------------------------------------------------------------------------- |
| 90d retention objects  | Tags: `Retention: 90d` | Same lifecycle rules as master: `90 day ` and `90 day Glacier expiration` |
| Archive prefix objects | Prefix: `archive`      | Same lifecycle rules as master                                            |

**Important**

> **Objects should be pushed with the proper tags** to trigger the replication.
> If the tags are added after the object creation, the object will not be replicated.

## Terraform

### Resources created by this module

| Account | Type                      | Terraform                                                      | Info                                                           |
| ------- | ------------------------- | -------------------------------------------------------------- | -------------------------------------------------------------- |
| common  | tf-aws-label (module)     | [common.tf](./common.tf)                                       | Tags for the AWS resources created by this module.             |
| master  | s3-bucket (module)        | [master_s3.tf](./master_s3.tf)                                 | Bucket with backup master copy.                                |
| master  | s3_bucket_metrics         | [master_metrics.tf](./master_metrics.tf)                       | Bucket metrics for each lifecycle rule.                        |
| master  | kms_key                   | [master_kms.tf](./master_kms.tf)                               | KMS key for master bucket encryption.                          |
| master  | iam_role                  | [replication_iam.tf](./replication_iam.tf)                     | Role replicate with encryption from the master to the replica. |
| master  | replication_configuration | [replication_configuration.tf](./replication_configuration.tf) | Set of rules for the bucket replication.                       |
| master  | lifecycle_rules           | [common.tf](./common.tf)                                       | Set of rules for the backup retention, based on object tags.   |
| replica | s3_bucket_policy          | [replication_iam.tf](./replication_iam.tf)                     | Role allow replication from the master replication role.       |
| replica | s3-bucket (module)        | [replica_s3.tf](./replica_s3.tf)                               | Bucket with replica master copy.                               |
| replica | s3_bucket_metrics         | [replica_metrics.tf](./replica_metrics.tf)                     | Bucket metrics for each lifecycle rule.                        |
| replica | aws_kms_key               | [replica_kms.tf](./replica_kms.tf)                             | KMS key for replica bucket encryption.                         |

### Providers

Due to the cross-account nature of this module, 2 providers are required,
one for the master account and region, and another for the replica.

| Account | Provider    |
| ------- | ----------- |
| master  | aws.master  |
| replica | aws.replica |

Example:

```hcl
provider "aws" {
  alias   = "master"
  region  = "us-east-1"
  profile = "master_account"
}

provider "aws" {
  alias   = "replica"
  region  = "eu-west-1"
  profile = "replica_account"
}

module "s3_backup_bucket" {
  source = "git::https://github.com/3scale-ops/tf-aws-s3-backup?ref=tags/v0.1.0"
  providers = {
    aws.master  = aws.master
    aws.replica = aws.replica
  }
  ...
}
```

### Inputs

| Variable             | Type   | Tag         | Default | Description                                             |
| -------------------- | ------ | ----------- | ------- | ------------------------------------------------------- |
| `prevent_destroy`    | bool   | -           | true    | Prevents accidental deletion of the critical resources. |
| `bucket_name_prefix` | string | -           | 3scale  | Bucket name prefix, as S3 bucket ids should be unique." |
| `environment`        | string | Environment | -       | Environment (dev/stg/pro)                               |
| `project`            | string | Project     | -       | Project (eng/saas)                                      |
| `workload`           | string | Workload    | backup  | Workload                                                |
| `tf_config`          | string | Terraform   | -       | Terraform configuration name                            |

`prevent_destroy` will prevent the destruction of the buckets if they are not empty.
KMS keys can be destroyed, as they will remain available and expire after 30 days. [Deleting AWS KMS keys](https://docs.aws.amazon.com/kms/latest/developerguide/deleting-keys.html#deleting-keys-how-it-works).


All the AWS resources will be tagged and named the `Tag` variables. More information at https://github.com/3scale-ops/tf-aws-label.
Buckets names will be also added as tag `Name` and generated using the following rule:

| Account | Bucket Naming                                                   | Example                             |
| ------- | --------------------------------------------------------------- | ----------------------------------- |
| master  | `bucket_name_prefix`-`environment`-`project`-`workload`         | 3scale-pro-ecommerce-backup         |
| replica | `bucket_name_prefix`-`environment`-`project`-`workload`-replica | 3scale-pro-ecommerce-backup-replica |

Example names generated by the following configuration:

```hcl
module "s3_backup_bucket" {
  source = "git::https://github.com/3scale-ops/tf-aws-s3-backup?ref=tags/v0.1.0"
  providers = {
    aws.master  = aws.master
    aws.replica = aws.replica
  }
  environment = "pro"
  project     = "ecommerce"
  tf_config   = "pro-ecommerce-backup-tf-stack"
}
```

### Outputs

| Variable                    | Type   | Description                         |
| --------------------------- | ------ | ----------------------------------- |
| `s3_master_bucket_id`       | string | The master bucket id (bucket name). |
| `s3_master_bucket_arn`      | string | The master bucket ARN.              |
| `kms_master_bucket_key_id`  | string | The master KMS bucket key id.       |
| `s3_replica_bucket_id`      | string | The name bucket id (bucket name).   |
| `s3_replica_bucket_arn`     | string | The replica bucket ARN.             |
| `kms_replica_bucket_key_id` | string | The replica KMS bucket key id.      |

### Example

```hcl
# ------------------------------------------------------------------------------
# providers.tf
# ------------------------------------------------------------------------------

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.50.0"
    }
  }
  required_version = ">= 0.13"
}

provider "aws" {
  alias   = "master"
  region  = "us-east-1"
  profile = "master_account"
}

provider "aws" {
  alias   = "replica"
  region  = "eu-west-1"
  profile = "replica_account"
}

# https://github.com/hashicorp/terraform-provider-aws/issues/9989
provider "aws" {
  region = "us-east-1"
}

# ------------------------------------------------------------------------------
# intputs.tf
# ------------------------------------------------------------------------------

locals {
  environment = "pro"
  project     = "ecommercd"
  workload    = "backup"
  type        = "s3"
  tf_config = format("%s-%s-%s-%s",
    local.environment, local.project, local.workload, local.type
  )
}

# ------------------------------------------------------------------------------
# main.tf
# ------------------------------------------------------------------------------

module "s3_backup_bucket" {
  source = "git::https://github.com/3scale-ops/tf-aws-s3-backup?ref=tags/v0.1.0"
  providers = {
    aws.master  = aws.master
    aws.replica = aws.replica
  }
  environment = local.environment
  project     = local.project
  workload    = local.workload
  tf_config   = local.tf_config
}

# ------------------------------------------------------------------------------
# outputs.tf
# ------------------------------------------------------------------------------

output "s3_master_bucket_id" {
  value       = module.s3_backup_bucket.s3_master_bucket_id
  description = "The S3 backups bucket id."
}

output "s3_master_bucket_arn" {
  value       = module.s3_backup_bucket.s3_master_bucket_arn
  description = "The S3 backups bucket name."
}

output "kms_master_bucket_key_id" {
  value       = module.s3_backup_bucket.kms_master_bucket_key_id
  description = "The KMS backups bucket key id."
}

output "s3_replica_bucket_id" {
  value       = module.s3_backup_bucket.s3_replica_bucket_id
  description = "The S3 backups bucket id."
}

output "s3_replica_bucket_arn" {
  value       = module.s3_backup_bucket.s3_replica_bucket_arn
  description = "The S3 backups bucket name."
}

output "kms_replica_bucket_key_id" {
  value       = module.s3_backup_bucket.kms_replica_bucket_key_id
  description = "The KMS backups bucket key id."
}
```

## Contributing

You can contribute by:

* Raising any issues you find using the operator
* Fixing issues by opening [Pull Requests](https://github.com/3scale-ops/tf-aws-s3-backup/pulls)
* Submitting a patch or opening a PR
* Improving documentation
* Talking about the operator

All bugs, tasks or enhancements are tracked as [GitHub issues](https://github.com/3scale-ops/tf-aws-s3-backup/issues).

## License

[tf-aws-s3-backup](https://github.com/3scale-ops/tf-aws-s3-backup/) module is under Apache 2.0 license. See the [LICENSE](LICENSE) file for details.
