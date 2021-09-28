resource "aws_s3_bucket_metric" "replica" {
  provider = aws.replica

  bucket = module.replica.s3_bucket_id
  name   = "All"
}

resource "aws_s3_bucket_metric" "replica_1y" {
  provider = aws.replica

  bucket = module.replica.s3_bucket_id
  name   = "1yRetention"

  filter {
    tags = {
      Retention = "1y"
    }
  }
}

resource "aws_s3_bucket_metric" "replica_1y_glacier" {
  provider = aws.replica

  bucket = module.replica.s3_bucket_id
  name   = "1yGlacierRetention"

  filter {
    tags = {
      Retention = "1y"
      Archive   = "Glacier"
    }
  }
}

resource "aws_s3_bucket_metric" "replica_90d" {
  provider = aws.replica

  bucket = module.replica.s3_bucket_id
  name   = "90dRetention"

  filter {
    tags = {
      Retention = "90d"
    }
  }
}

resource "aws_s3_bucket_metric" "replica_90d_glacier" {
  provider = aws.replica

  bucket = module.replica.s3_bucket_id
  name   = "90dGlacierRetention"

  filter {
    tags = {
      Retention = "90d"
      Archive   = "Glacier"
    }
  }
}

resource "aws_s3_bucket_metric" "replica_30d" {
  provider = aws.replica

  bucket = module.replica.s3_bucket_id
  name   = "30dRetention"

  filter {
    tags = {
      Retention = "30d"
    }
  }
}

resource "aws_s3_bucket_metric" "replica_7d" {
  provider = aws.replica

  bucket = module.replica.s3_bucket_id
  name   = "7dRetention"

  filter {
    tags = {
      Retention = "7d"
    }
  }
}

resource "aws_s3_bucket_metric" "replica_3d" {
  provider = aws.replica

  bucket = module.replica.s3_bucket_id
  name   = "3dRetention"

  filter {
    tags = {
      Retention = "3d"
    }
  }
}
