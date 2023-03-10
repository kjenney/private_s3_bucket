terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 4.57.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "b" {
  bucket = "kens-tf-test-bucket23"
  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_acl" "example" {
  bucket = aws_s3_bucket.b.id
  acl    = "private"
}

resource "aws_s3_bucket_lifecycle_configuration" "bucket-lifecycle" {
  bucket             = aws_s3_bucket.b.id
  rule {
    id               = "dev_lifecycle_30_days"
    status           = "Enabled"
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
    noncurrent_version_expiration {
      noncurrent_days = 1
    }
    expiration {
      days          = 30
    }
  }
}
resource "aws_iam_policy" "bucket-iam-policy" {
  name               = "s3_access"
  path               = "/"
  description        = "Allow access to S3"
  policy = jsonencode({
    Version          = "2012-10-17"
    Statement        = [
      {
        Action = [
          "s3:*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}
resource "aws_iam_role" "bucket-iam-role" {
  name               = "s3-bucket-role"
  path               = "/"
  description        = "Allow access to S3"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}
resource "aws_iam_role_policy_attachment" "bucket-iam-attach" {
  role               = aws_iam_role.bucket-iam-role.name
  policy_arn         = aws_iam_policy.bucket-iam-policy.arn
}

resource "aws_s3_bucket_policy" "bucket-iam-policy" {
  bucket             = aws_s3_bucket.b.id
  policy             = data.aws_iam_policy_document.allow_access_from_iam_role.json
}

data "aws_iam_policy_document" "allow_access_from_iam_role" {
  statement {
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    effect        = "Deny"
    actions       = ["s3:*"]
    resources = [
      aws_s3_bucket.b.arn,
      "${aws_s3_bucket.b.arn}/*",
    ]
    condition {
      test     = "StringNotLike"
      variable = "aws:userId"
      values = [
        "${aws_iam_role.bucket-iam-role.unique_id}:*",
        "${data.aws_caller_identity.current.account_id}"
      ]
    }
  }
}
