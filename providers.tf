terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">=3.5.0"
      configuration_aliases = [aws.master, aws.replica]
    }
  }
}

data "aws_region" "master" { provider = aws.master }
data "aws_caller_identity" "master" { provider = aws.master }
data "aws_region" "replica" { provider = aws.replica }
data "aws_caller_identity" "replica" { provider = aws.replica }
