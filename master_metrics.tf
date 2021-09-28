resource "aws_s3_bucket_metric" "master" {
  provider = aws.master

  bucket = module.master.s3_bucket_id
  name   = "All"
}

resource "aws_s3_bucket_metric" "master_1y" {
  provider = aws.master

  bucket = module.master.s3_bucket_id
  name   = "1yRetention"

  filter {
    tags = {
      Retention = "1y"
    }
  }
}

resource "aws_s3_bucket_metric" "master_1y_glacier" {
  provider = aws.master

  bucket = module.master.s3_bucket_id
  name   = "1yGlacierRetention"

  filter {
    tags = {
      Retention = "1y"
      Archive   = "Glacier"
    }
  }
}

resource "aws_s3_bucket_metric" "master_90d" {
  provider = aws.master

  bucket = module.master.s3_bucket_id
  name   = "90dRetention"

  filter {
    tags = {
      Retention = "90d"
    }
  }
}

resource "aws_s3_bucket_metric" "master_90d_glacier" {
  provider = aws.master

  bucket = module.master.s3_bucket_id
  name   = "90dGlacierRetention"

  filter {
    tags = {
      Retention = "90d"
      Archive   = "Glacier"
    }
  }
}

resource "aws_s3_bucket_metric" "master_30d" {
  provider = aws.master

  bucket = module.master.s3_bucket_id
  name   = "30dRetention"

  filter {
    tags = {
      Retention = "30d"
    }
  }
}

resource "aws_s3_bucket_metric" "master_7d" {
  provider = aws.master

  bucket = module.master.s3_bucket_id
  name   = "7dRetention"

  filter {
    tags = {
      Retention = "7d"
    }
  }
}

resource "aws_s3_bucket_metric" "master_3d" {
  provider = aws.master

  bucket = module.master.s3_bucket_id
  name   = "3dRetention"

  filter {
    tags = {
      Retention = "3d"
    }
  }
}
