terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Random suffix for unique bucket name
resource "random_string" "bucket_suffix" {
  length  = 5
  special = false
  upper   = false
}

# S3 Bucket
resource "aws_s3_bucket" "project_bucket" {
  bucket = "tf-project2-bucket-${random_string.bucket_suffix.result}"
}

# Versioning ENABLED
resource "aws_s3_bucket_versioning" "project_bucket_versioning" {
  bucket = aws_s3_bucket.project_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
  depends_on = [aws_s3_bucket.project_bucket]
}

# Static Website Hosting
resource "aws_s3_bucket_website_configuration" "project_bucket_website_config" {
  bucket = aws_s3_bucket.project_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }

  depends_on = [aws_s3_bucket.project_bucket]
}

# ✅ Public Access Block DISABLED (Required for public website)
resource "aws_s3_bucket_public_access_block" "project_bucket" {
  bucket = aws_s3_bucket.project_bucket.id

  block_public_acls       = false
  block_public_policy     = false  # ← KEY: Enables public policy
  ignore_public_acls      = false
  restrict_public_buckets = false

  depends_on = [aws_s3_bucket.project_bucket]
}

# ✅ Lifecycle Configuration - FIXED filter block
resource "aws_s3_bucket_lifecycle_configuration" "project_bucket_lifecycle" {
  bucket = aws_s3_bucket.project_bucket.id

  rule {
    id     = "delete-after-30-days"
    status = "Enabled"

    filter {
      prefix = ""  # ← FIXED: Empty prefix = all objects
    }

    expiration {
      days = 30
    }
  }

  # ✅ FIXED: Correct resource name
  depends_on = [aws_s3_bucket_versioning.project_bucket_versioning]
}

# ✅ Public Read Policy - FIXED JSON
resource "aws_s3_bucket_policy" "public_read" {
  bucket = aws_s3_bucket.project_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "PublicReadGetObject"
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "arn:aws:s3:::${aws_s3_bucket.project_bucket.id}/*"  # ✅ "Resource" singular
    }]
  })

  depends_on = [aws_s3_bucket_public_access_block.project_bucket]
}

# Outputs
output "bucket_arn" {
  value = aws_s3_bucket.project_bucket.arn
}

output "bucket_name" {
  value = aws_s3_bucket.project_bucket.id
}

output "website_domain" {
  value = "s3-website-us-east-1.amazonaws.com"
}

output "website_url" {
  value = "${aws_s3_bucket.project_bucket.bucket}.s3-website-us-east-1.amazonaws.com"
}

