terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Lambda@Edge must be created in us-east-1
provider "aws" {
  region = "us-east-1"
  alias  = "lambda_edge"
}

# Primary provider
provider "aws" {
  region = var.aws_region
}

# S3 bucket for website content
resource "aws_s3_bucket" "pictures_website" {
  bucket = "secure-pictures-site-${random_string.bucket_suffix.result}"
  
  tags = {
    Name        = "Secure Pictures Website"
    Environment = var.environment
    Purpose     = "Lambda@Edge Authentication Demo"
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

resource "aws_s3_bucket_server_side_encryption_configuration" "pictures_website_encryption" {
  bucket = aws_s3_bucket.pictures_website.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access - only CloudFront should access
resource "aws_s3_bucket_public_access_block" "pictures_website_pab" {
  bucket = aws_s3_bucket.pictures_website.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CloudFront Origin Access Control
resource "aws_cloudfront_origin_access_control" "pictures_website_oac" {
  name                              = "secure-pictures-site-oac"
  description                       = "OAC for secure pictures website"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# Upload website files
resource "aws_s3_object" "index_html" {
  bucket       = aws_s3_bucket.pictures_website.id
  key          = "index.html"
  content      = file("${path.module}/website/index.html")
  content_type = "text/html"
  etag         = filemd5("${path.module}/website/index.html")
}

resource "aws_s3_object" "login_html" {
  bucket       = aws_s3_bucket.pictures_website.id
  key          = "login.html"
  content      = file("${path.module}/website/login.html")
  content_type = "text/html"
  etag         = filemd5("${path.module}/website/login.html")
}

resource "aws_s3_object" "gallery_html" {
  bucket       = aws_s3_bucket.pictures_website.id
  key          = "gallery.html"
  content      = file("${path.module}/website/gallery.html")
  content_type = "text/html"
  etag         = filemd5("${path.module}/website/gallery.html")
}

resource "aws_s3_object" "styles_css" {
  bucket       = aws_s3_bucket.pictures_website.id
  key          = "assets/styles.css"
  content      = file("${path.module}/website/assets/styles.css")
  content_type = "text/css"
  etag         = filemd5("${path.module}/website/assets/styles.css")
}

# Create image metadata file (JSON) that contains the image URLs and info
resource "aws_s3_object" "images_metadata" {
  bucket       = aws_s3_bucket.pictures_website.id
  key          = "images/metadata.json"
  content      = jsonencode({
    images = var.sample_images
    last_updated = timestamp()
  })
  content_type = "application/json"
  etag         = md5(jsonencode({
    images = var.sample_images
    last_updated = timestamp()
  }))
}

# IAM role for Lambda@Edge
resource "aws_iam_role" "lambda_edge_auth_role" {
  provider = aws.lambda_edge
  name     = "lambda-edge-auth-role"

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
  provider   = aws.lambda_edge
  role       = aws_iam_role.lambda_edge_auth_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Lambda@Edge function for authentication
resource "aws_lambda_function" "auth_function" {
  provider         = aws.lambda_edge
  filename         = "auth_function.zip"
  function_name    = "pictures-site-auth"
  role            = aws_iam_role.lambda_edge_auth_role.arn
  handler         = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.auth_function_zip.output_base64sha256
  runtime         = "python3.9"
  timeout         = 5

  tags = {
    Name        = "Pictures Site Auth"
    Environment = var.environment
  }

  depends_on = [data.archive_file.auth_function_zip]
}

# Create ZIP file for auth Lambda function
data "archive_file" "auth_function_zip" {
  type        = "zip"
  output_path = "auth_function.zip"
  source {
    content  = file("${path.module}/lambda/auth_function.py")
    filename = "lambda_function.py"
  }
}

# Lambda@Edge function for security headers
resource "aws_lambda_function" "security_headers_function" {
  provider         = aws.lambda_edge
  filename         = "security_headers.zip"
  function_name    = "pictures-site-security-headers"
  role            = aws_iam_role.lambda_edge_auth_role.arn
  handler         = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.security_headers_zip.output_base64sha256
  runtime         = "python3.9"
  timeout         = 5

  tags = {
    Name        = "Pictures Site Security Headers"
    Environment = var.environment
  }

  depends_on = [data.archive_file.security_headers_zip]
}

data "archive_file" "security_headers_zip" {
  type        = "zip"
  output_path = "security_headers.zip"
  source {
    content  = file("${path.module}/lambda/security_headers.py")
    filename = "lambda_function.py"
  }
}

# CloudFront Distribution with Lambda@Edge authentication
resource "aws_cloudfront_distribution" "pictures_website_distribution" {
  origin {
    domain_name              = aws_s3_bucket.pictures_website.bucket_regional_domain_name
    origin_id                = "S3-${aws_s3_bucket.pictures_website.id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.pictures_website_oac.id
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  comment             = "Secure Pictures Website with Lambda@Edge Auth"

  # Default cache behavior - public content
  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${aws_s3_bucket.pictures_website.id}"
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      headers      = ["Authorization", "CloudFront-Viewer-Country"]
      cookies {
        forward = "all"
      }
    }

    # Add security headers to all responses
    lambda_function_association {
      event_type   = "origin-response"
      lambda_arn   = aws_lambda_function.security_headers_function.qualified_arn
      include_body = false
    }

    min_ttl     = 0
    default_ttl = 86400
    max_ttl     = 31536000
  }

  # Protected content - requires authentication
  ordered_cache_behavior {
    path_pattern     = "/gallery*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.pictures_website.id}"

    forwarded_values {
      query_string = true
      headers      = ["Authorization", "CloudFront-Viewer-Country", "User-Agent"]
      cookies {
        forward = "all"
      }
    }

    # Authentication check for gallery
    lambda_function_association {
      event_type   = "viewer-request"
      lambda_arn   = aws_lambda_function.auth_function.qualified_arn
      include_body = false
    }

    # Add security headers
    lambda_function_association {
      event_type   = "origin-response"
      lambda_arn   = aws_lambda_function.security_headers_function.qualified_arn
      include_body = false
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0  # Don't cache protected content
    max_ttl                = 0
  }

  # Protected images - requires authentication
  ordered_cache_behavior {
    path_pattern     = "/images/*"
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.pictures_website.id}"

    forwarded_values {
      query_string = false
      headers      = ["Authorization", "Referer"]
      cookies {
        forward = "all"
      }
    }

    # Authentication check for images
    lambda_function_association {
      event_type   = "viewer-request"
      lambda_arn   = aws_lambda_function.auth_function.qualified_arn
      include_body = false
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600  # Cache authenticated images for 1 hour
    max_ttl                = 86400
  }

  price_class = var.cloudfront_price_class

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name        = "Secure Pictures Website"
    Environment = var.environment
    Purpose     = "Lambda@Edge Authentication Demo"
  }
}

# S3 bucket policy to allow CloudFront access
resource "aws_s3_bucket_policy" "pictures_website_policy" {
  bucket = aws_s3_bucket.pictures_website.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipal"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.pictures_website.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.pictures_website_distribution.arn
          }
        }
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.pictures_website_pab]
}