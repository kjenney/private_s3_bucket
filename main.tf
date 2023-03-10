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

data "aws_ami" "al2" {
 most_recent = true


 filter {
   name   = "owner-alias"
   values = ["amazon"]
 }


 filter {
   name   = "name"
   values = ["amzn2-ami-hvm*"]
 }
}

data "aws_iam_policy" "AmazonSSMManagedInstanceCore" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_s3_bucket" "b" {
  bucket = var.bucket_name
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
resource "aws_iam_role" "allow_connectivity_to_private_bucket" {
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
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          AWS = data.aws_caller_identity.current.account_id
        }
      },
    ]
  })
}

resource "aws_iam_instance_profile" "allow_connectivity_to_private_bucket" {
  name = "allow_connectivity_to_private_bucket"
  role = aws_iam_role.allow_connectivity_to_private_bucket.name
}

resource "aws_iam_role_policy_attachment" "bucket-iam-attach" {
  role               = aws_iam_role.allow_connectivity_to_private_bucket.name
  policy_arn         = aws_iam_policy.bucket-iam-policy.arn
}

resource "aws_iam_role_policy_attachment" "ssm-iam-attach" {
  role               = aws_iam_role.allow_connectivity_to_private_bucket.name
  policy_arn         = data.aws_iam_policy.AmazonSSMManagedInstanceCore.arn
}

resource "aws_s3_bucket_policy" "bucket-iam-policy" {
  bucket             = aws_s3_bucket.b.id
  policy             = data.aws_iam_policy_document.allow_access_from_iam_role.json
  depends_on         = [
    aws_s3_bucket_lifecycle_configuration.bucket-lifecycle
  ]
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
        "${aws_iam_role.allow_connectivity_to_private_bucket.unique_id}:*",
        "${data.aws_caller_identity.current.account_id}"
      ]
    }
  }
}

## VPC created separately

resource "aws_security_group" "allow_outbound" {
  name        = "allow_outbound"
  description = "Allow outbound traffic"
  vpc_id      = var.vpc_id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}

resource "aws_instance" "bucket_test" {
  ami                         = data.aws_ami.al2.id
  instance_type               = "t3.large"
  vpc_security_group_ids      = [aws_security_group.allow_outbound.id]
  iam_instance_profile        = aws_iam_instance_profile.allow_connectivity_to_private_bucket.id
  subnet_id                   = var.subnet_id

  tags = {
    Name = "HelloBucket"
  }
}


