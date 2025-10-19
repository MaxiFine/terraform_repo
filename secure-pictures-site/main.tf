# Simplified Lambda@Edge Demo - without OAI due to permission constraints
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Default provider for most resources
provider "aws" {
  region = var.aws_region
}

# Lambda@Edge must be in us-east-1
provider "aws" {
  alias  = "lambda_edge"
  region = "us-east-1"
}

# S3 bucket for website content (public for demo)
resource "aws_s3_bucket" "pictures_website" {
  bucket = "secure-pictures-site-${random_string.bucket_suffix.result}"
  
  tags = {
    Name        = "Secure Pictures Website"
    Project     = "lambda-edge-auth"
  }
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket_versioning" "pictures_website_versioning" {
  bucket = aws_s3_bucket.pictures_website.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable public access for demo (not recommended for production)
resource "aws_s3_bucket_public_access_block" "pictures_website_pab" {
  bucket = aws_s3_bucket.pictures_website.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Public read policy for S3 bucket (demo only)
resource "aws_s3_bucket_policy" "pictures_website_policy" {
  bucket = aws_s3_bucket.pictures_website.id
  depends_on = [aws_s3_bucket_public_access_block.pictures_website_pab]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.pictures_website.arn}/*"
      }
    ]
  })
}

# Configure S3 bucket as static website
resource "aws_s3_bucket_website_configuration" "pictures_website_config" {
  bucket = aws_s3_bucket.pictures_website.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# Upload website files
resource "aws_s3_object" "index_html" {
  bucket       = aws_s3_bucket.pictures_website.id
  key          = "index.html"
  content_type = "text/html"
  content = templatefile("${path.module}/website/index.html", {
    cloudfront_domain = aws_cloudfront_distribution.pictures_website_cdn.domain_name
  })
}

resource "aws_s3_object" "login_html" {
  bucket       = aws_s3_bucket.pictures_website.id
  key          = "login.html"
  content_type = "text/html"
  content = file("${path.module}/website/login.html")
}

resource "aws_s3_object" "gallery_html" {
  bucket       = aws_s3_bucket.pictures_website.id
  key          = "gallery.html"
  content_type = "text/html"
  content = file("${path.module}/website/gallery.html")
}

resource "aws_s3_object" "styles_css" {
  bucket       = aws_s3_bucket.pictures_website.id
  key          = "assets/styles.css"
  content_type = "text/css"
  content = file("${path.module}/website/styles.css")
}

resource "aws_s3_object" "images_metadata" {
  bucket       = aws_s3_bucket.pictures_website.id
  key          = "data/images.json"
  content_type = "application/json"
  content = jsonencode({
    images = var.sample_images
  })
}

# IAM role for Lambda@Edge functions
resource "aws_iam_role" "lambda_edge_auth_role" {
  name = "lambda-edge-auth-role"
  
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

resource "aws_iam_role_policy_attachment" "lambda_edge_auth_basic" {
  role       = aws_iam_role.lambda_edge_auth_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Lambda function for authentication (must be in us-east-1)
resource "aws_lambda_function" "auth_function" {
  provider = aws.lambda_edge

  filename         = "lambda/auth_function.zip"
  function_name    = "pictures-site-auth"
  role            = aws_iam_role.lambda_edge_auth_role.arn
  handler         = "auth_function.lambda_handler"
  source_code_hash = data.archive_file.auth_function_zip.output_base64sha256
  runtime         = "python3.9"
  timeout         = 5
  
  tags = {
    Name    = "Pictures Site Auth Function"
    Project = "lambda-edge-auth"
  }
}

# Lambda function for security headers (must be in us-east-1)
resource "aws_lambda_function" "security_headers_function" {
  provider = aws.lambda_edge
  
  filename         = "lambda/security_headers.zip"
  function_name    = "pictures-site-security-headers"
  role            = aws_iam_role.lambda_edge_auth_role.arn
  handler         = "security_headers.lambda_handler"
  source_code_hash = data.archive_file.security_headers_zip.output_base64sha256
  runtime         = "python3.9"
  timeout         = 5
  
  tags = {
    Name    = "Pictures Site Security Headers Function"
    Project = "lambda-edge-auth"
  }
}

# Archive Lambda functions
data "archive_file" "auth_function_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/auth_function.py"
  output_path = "${path.module}/lambda/auth_function.zip"
}

data "archive_file" "security_headers_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/security_headers.py"
  output_path = "${path.module}/lambda/security_headers.zip"
}

# CloudFront Distribution (simplified without OAI)
resource "aws_cloudfront_distribution" "pictures_website_cdn" {
  depends_on = [
    aws_lambda_function.auth_function,
    aws_lambda_function.security_headers_function
  ]

  origin {
    domain_name = aws_s3_bucket_website_configuration.pictures_website_config.website_endpoint
    origin_id   = "S3-${aws_s3_bucket.pictures_website.id}"
    
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  enabled             = true
  default_root_object = "index.html"
  price_class         = var.cloudfront_price_class

  # Default cache behavior (homepage - public)
  default_cache_behavior {
    target_origin_id       = "S3-${aws_s3_bucket.pictures_website.id}"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    # Add security headers to all responses
    lambda_function_association {
      event_type   = "origin-response"
      lambda_arn   = "${aws_lambda_function.security_headers_function.arn}:${aws_lambda_function.security_headers_function.version}"
      include_body = false
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }

  # Protected gallery behavior
  ordered_cache_behavior {
    path_pattern           = "/gallery*"
    target_origin_id       = "S3-${aws_s3_bucket.pictures_website.id}"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    forwarded_values {
      query_string = true
      cookies {
        forward = "all"
      }
    }

    # Authentication function on viewer request
    lambda_function_association {
      event_type   = "viewer-request"
      lambda_arn   = "${aws_lambda_function.auth_function.arn}:${aws_lambda_function.auth_function.version}"
      include_body = false
    }

    # Security headers on response
    lambda_function_association {
      event_type   = "origin-response"
      lambda_arn   = "${aws_lambda_function.security_headers_function.arn}:${aws_lambda_function.security_headers_function.version}"
      include_body = false
    }

    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
  }

  # Protected images behavior
  ordered_cache_behavior {
    path_pattern           = "/data/*"
    target_origin_id       = "S3-${aws_s3_bucket.pictures_website.id}"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    forwarded_values {
      query_string = true
      cookies {
        forward = "all"
      }
    }

    # Authentication function
    lambda_function_association {
      event_type   = "viewer-request"
      lambda_arn   = "${aws_lambda_function.auth_function.arn}:${aws_lambda_function.auth_function.version}"
      include_body = false
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name    = "Pictures Website CDN"
    Project = "lambda-edge-auth"
  }
}