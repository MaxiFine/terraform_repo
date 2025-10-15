terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Primary provider for most resources
provider "aws" {
  region = "us-east-1"
  alias  = "us_east_1"
}

# Lambda@Edge must be created in us-east-1
provider "aws" {
  region = "us-east-1"
  alias  = "lambda_edge"
}

# S3 bucket for static website
resource "aws_s3_bucket" "website_bucket" {
  provider = aws.us_east_1
  bucket   = "mx-lambda-edge-demo-${random_string.bucket_suffix.result}"
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket_public_access_block" "website_bucket_pab" {
  provider = aws.us_east_1
  bucket   = aws_s3_bucket.website_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_website_configuration" "website_bucket_config" {
  provider = aws.us_east_1
  bucket   = aws_s3_bucket.website_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_policy" "website_bucket_policy" {
  provider = aws.us_east_1
  bucket   = aws_s3_bucket.website_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.website_bucket.arn}/*"
      },
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.website_bucket_pab]
}

# Upload sample HTML files
resource "aws_s3_object" "index_html" {
  provider     = aws.us_east_1
  bucket       = aws_s3_bucket.website_bucket.id
  key          = "index.html"
  content      = file("${path.module}/website/index.html")
  content_type = "text/html"
}

resource "aws_s3_object" "about_html" {
  provider     = aws.us_east_1
  bucket       = aws_s3_bucket.website_bucket.id
  key          = "about.html"
  content      = file("${path.module}/website/about.html")
  content_type = "text/html"
}

# IAM role for Lambda@Edge
resource "aws_iam_role" "lambda_edge_role" {
  provider = aws.lambda_edge
  name     = "lambda-edge-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = [
            "lambda.amazonaws.com",
            "edgelambda.amazonaws.com"
          ]
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_edge_basic" {
  provider   = aws.lambda_edge
  role       = aws_iam_role.lambda_edge_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Lambda@Edge function for adding security headers
resource "aws_lambda_function" "security_headers" {
  provider         = aws.lambda_edge
  filename         = "security_headers.zip"
  function_name    = "security-headers-lambda-edge"
  role            = aws_iam_role.lambda_edge_role.arn
  handler         = "index.handler"
  source_code_hash = data.archive_file.security_headers_zip.output_base64sha256
  runtime         = "nodejs18.x"
  timeout         = 5

  depends_on = [data.archive_file.security_headers_zip]
}

# Create ZIP file for Lambda function
data "archive_file" "security_headers_zip" {
  type        = "zip"
  output_path = "security_headers.zip"
  source {
    content = templatefile("${path.module}/lambda/security-headers.js", {})
    filename = "index.js"
  }
}

# Lambda@Edge function for A/B testing
resource "aws_lambda_function" "ab_testing" {
  provider         = aws.lambda_edge
  filename         = "ab_testing.zip"
  function_name    = "ab-testing-lambda-edge"
  role            = aws_iam_role.lambda_edge_role.arn
  handler         = "index.handler"
  source_code_hash = data.archive_file.ab_testing_zip.output_base64sha256
  runtime         = "nodejs18.x"
  timeout         = 5

  depends_on = [data.archive_file.ab_testing_zip]
}

data "archive_file" "ab_testing_zip" {
  type        = "zip"
  output_path = "ab_testing.zip"
  source {
    content = templatefile("${path.module}/lambda/ab-testing.js", {})
    filename = "index.js"
  }
}

# CloudFront Origin Access Identity
resource "aws_cloudfront_origin_access_identity" "website_oai" {
  provider = aws.us_east_1
  comment  = "OAI for Lambda@Edge demo website"
}

# CloudFront Distribution with Lambda@Edge
resource "aws_cloudfront_distribution" "website_distribution" {
  provider = aws.us_east_1

  origin {
    domain_name = aws_s3_bucket.website_bucket.bucket_regional_domain_name
    origin_id   = "S3-${aws_s3_bucket.website_bucket.id}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.website_oai.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  comment             = "Lambda@Edge Demo Distribution"

  # Default cache behavior with Lambda@Edge
  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${aws_s3_bucket.website_bucket.id}"
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    # Attach Lambda@Edge functions
    lambda_function_association {
      event_type   = "viewer-request"
      lambda_arn   = aws_lambda_function.ab_testing.qualified_arn
      include_body = false
    }

    lambda_function_association {
      event_type   = "origin-response"
      lambda_arn   = aws_lambda_function.security_headers.qualified_arn
      include_body = false
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }

  # Cache behavior for /api/* paths
  ordered_cache_behavior {
    path_pattern     = "/api/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.website_bucket.id}"

    forwarded_values {
      query_string = true
      headers      = ["Authorization"]
      cookies {
        forward = "all"
      }
    }

    viewer_protocol_policy = "https-only"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name        = "Lambda@Edge Demo"
    Environment = "Learning"
    Purpose     = "Edge Computing Demo"
  }
}

# Update S3 bucket policy to allow CloudFront access
resource "aws_s3_bucket_policy" "website_bucket_cloudfront_policy" {
  provider = aws.us_east_1
  bucket   = aws_s3_bucket.website_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontAccess"
        Effect    = "Allow"
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.website_oai.iam_arn
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.website_bucket.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.website_bucket_pab]
}