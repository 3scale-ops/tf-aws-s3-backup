# ------------------------------------------------------------------------------
# IAM role for S3 to assume the role for replication
# ------------------------------------------------------------------------------

resource "aws_iam_policy_attachment" "replication" {
  provider = aws.master

  name       = format("%s-replication", local.master_bucket_id)
  roles      = [aws_iam_role.replication.name]
  policy_arn = aws_iam_policy.replication.arn
}

# master-replica replication IAM role ------------------------------------------
resource "aws_iam_role" "replication" {
  provider = aws.master

  name               = format("%s-replication", local.master_bucket_id)
  description        = "Allow S3 to assume the role for replication"
  assume_role_policy = data.aws_iam_policy_document.s3_assume.json

  tags = merge(
    module.labels.tags,
    tomap({ "Name" = format("%s-replication", local.master_bucket_id) })
  )
}

# master-replica replication S3 assume role policy document --------------------
data "aws_iam_policy_document" "s3_assume" {

  statement {
    sid    = "AllowPrimaryToAssumeServiceRole"
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
  }
}

# master-replica replication IAM policy ----------------------------------------
resource "aws_iam_policy" "replication" {
  provider = aws.master

  name   = format("%s-replication", local.master_bucket_id)
  policy = data.aws_iam_policy_document.replication.json

  tags = merge(
    module.labels.tags,
    tomap({ "Name" = format("%s-replication", local.master_bucket_id) })
  )
}


# master-replica replication IAM policy document -------------------------------
data "aws_iam_policy_document" "replication" {

  # s3:GetReplicationConfiguration and s3:ListBucket—Permissions
  # for these actions on the source bucket allow Amazon S3
  # to retrieve the replication configuration and list bucket content
  statement {
    sid    = "AllowPrimaryToGetReplicationConfiguration"
    effect = "Allow"
    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket"
    ]
    resources = [
      format("arn:aws:s3:::%s", local.master_bucket_id)
    ]
  }

  # s3:GetObjectVersionForReplication and s3:GetObjectVersionAcl — Permissions
  # for these actions granted on all objects allow Amazon S3 to get a specific
  # object version and access control list (ACL) associated with objects.
  # s3:GetObjectVersionTagging — Permissions for this action on objects in
  # the source bucket allow Amazon S3 to read object tags for replication.
  statement {
    sid    = "AllowPrimaryToGetObjectVersion"
    effect = "Allow"
    actions = [
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging"
    ]
    resources = [
      format("arn:aws:s3:::%s/*", local.master_bucket_id)
    ]
  }

  # s3:ReplicateObject, s3:ReplicateDelete and s3:ReplicateTags — Permissions
  # for these actions on objects in all destination buckets allow Amazon S3
  # to replicate objects, tags or delete markers to the destination buckets.
  # s3:ObjectOwnerOverrideToBucketOwner — Permissions to grant Amazon S3
  # to change replica ownership.
  statement {
    sid    = "AllowPrimaryToReplicate"
    effect = "Allow"
    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags",
      "s3:ObjectOwnerOverrideToBucketOwner"
    ]
    resources = [
      format("%s/*", module.replica.s3_bucket_arn)
    ]
  }

  # kms:Decrypt - Permissions for the KMS key used to decrypt the source object
  # Note: When an S3 Bucket Key is enabled for the source and destination bucket,
  # the encryption context will be the bucket Amazon Resource Name (ARN)
  # and not the object ARN, for example, arn:aws:s3:::bucket_ARN.
  statement {
    actions = [
      "kms:Decrypt"
    ]
    effect = "Allow"
    condition {
      test     = "StringLike"
      variable = "kms:ViaService"
      values   = ["s3.${data.aws_region.master.name}.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:s3:arn"
      values   = [format("arn:aws:s3:::%s", local.master_bucket_id)]
    }
    resources = [aws_kms_key.master.arn]
  }

  # kms:Encrypt - Permissions for the KMS key used to encrypt the object replica
  # Note: When an S3 Bucket Key is enabled for the source and destination bucket,
  # the encryption context will be the bucket Amazon Resource Name (ARN)
  # and not the object ARN, for example, arn:aws:s3:::bucket_ARN.
  statement {
    actions = [
      "kms:Encrypt"
    ]
    effect = "Allow"
    condition {
      test     = "StringLike"
      variable = "kms:ViaService"
      values   = ["s3.${data.aws_region.replica.name}.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:s3:arn"
      values   = [format("%s", module.replica.s3_bucket_arn)]
    }
    resources = [aws_kms_key.replica.arn]
  }

}

# ------------------------------------------------------------------------------
# Replica Bucket Policy
# ------------------------------------------------------------------------------

# replica bucket policy  -------------------------------------------------------
resource "aws_s3_bucket_policy" "replica" {
  provider = aws.replica

  bucket = module.replica.s3_bucket_id
  policy = data.aws_iam_policy_document.replica.json
}

# replica bucket policy document -----------------------------------------------
data "aws_iam_policy_document" "replica" {
  statement {
    sid    = "Permissions on objects"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.replication.arn]
    }
    actions = [
      "s3:ReplicateDelete",
      "s3:ReplicateObject",
      "s3:ReplicateTags",
      "s3:GetObjectVersionTagging",
    ]
    resources = [format("%s/*", module.replica.s3_bucket_arn)]
  }

  statement {
    sid    = "Permissions on bucket"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.replication.arn]
    }
    actions = [
      "s3:List*",
      "s3:GetBucketVersioning",
      "s3:PutBucketVersioning"
    ]
    resources = [module.replica.s3_bucket_arn]
  }

  statement {
    sid    = "Allow changing replica ownership"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [data.aws_caller_identity.master.id]
    }
    actions   = ["s3:ObjectOwnerOverrideToBucketOwner"]
    resources = [format("%s/*", module.replica.s3_bucket_arn)]
  }

}
