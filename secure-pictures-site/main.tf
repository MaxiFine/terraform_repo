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
  content = <<-EOT
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Secure Pictures - Lambda@Edge Demo</title>
    <link rel="stylesheet" href="assets/styles.css">
</head>
<body>
    <div class="container">
        <h1>🔐 Secure Pictures Website</h1>
        <h2>Lambda@Edge Authentication Demo</h2>
        
        <p>Welcome to our secure pictures gallery! This site demonstrates AWS Lambda@Edge authentication.</p>
        
        <h3>📸 What's Here?</h3>
        <ul>
            <li><strong>Public Homepage</strong> - You're here now (no authentication needed)</li>
            <li><strong>Protected Gallery</strong> - Requires authentication to view pictures</li>
            <li><strong>Login System</strong> - Uses Lambda@Edge for serverless authentication</li>
        </ul>
        
        <h3>🚀 Try It Out!</h3>
        <div>
            <a href="gallery.html" class="btn">🖼️ View Gallery (Protected)</a>
            <a href="login.html" class="btn">🔑 Login Page</a>
        </div>
        
        <h3>🛡️ How It Works</h3>
        <p>This demo uses <strong>AWS Lambda@Edge</strong> functions that run at CloudFront edge locations to:</p>
        <ul>
            <li>Check authentication cookies on protected routes</li>
            <li>Redirect unauthenticated users to login</li>
            <li>Add security headers to all responses</li>
        </ul>
        
        <h3>🎯 Demo Credentials</h3>
        <div class="auth-indicator">
            <strong>Username:</strong> demo<br>
            <strong>Password:</strong> password123
        </div>
        
        <p><small>💡 This is a learning demo - in production, use proper authentication services and never hardcode credentials!</small></p>
    </div>
</body>
</html>
EOT
}

resource "aws_s3_object" "login_html" {
  bucket       = aws_s3_bucket.pictures_website.id
  key          = "login.html"
  content_type = "text/html"
  content = <<-EOT
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Login - Secure Pictures</title>
    <link rel="stylesheet" href="assets/styles.css">
</head>
<body>
    <div class="container">
        <div class="login-box">
            <h1>🔑 Login</h1>
            <p>Please login to access the protected gallery</p>
            
            <form id="loginForm">
                <div class="form-group">
                    <label for="username">Username:</label>
                    <input type="text" id="username" name="username" required>
                </div>
                
                <div class="form-group">
                    <label for="password">Password:</label>
                    <input type="password" id="password" name="password" required>
                </div>
                
                <button type="submit" class="btn">Login</button>
            </form>
            
            <div id="loginMessage"></div>
            
            <div style="margin-top: 20px; padding: 15px; background: #f0f0f0; border-radius: 5px;">
                <h3>Demo Credentials:</h3>
                <p><strong>Username:</strong> demo<br><strong>Password:</strong> password123</p>
                <p><strong>Username:</strong> admin<br><strong>Password:</strong> admin123</p>
            </div>
            
            <p style="margin-top: 20px;">
                <a href="index.html" class="btn">← Back to Home</a>
            </p>
        </div>
    </div>

    <script>
        document.getElementById('loginForm').addEventListener('submit', function(e) {
            e.preventDefault();
            
            const username = document.getElementById('username').value;
            const password = document.getElementById('password').value;
            const messageDiv = document.getElementById('loginMessage');
            
            // Demo authentication
            const ALLOWED_USERS = {
                "demo": "password123",
                "admin": "admin123",
                "user1": "mypassword"
            };
            
            if (ALLOWED_USERS[username] && ALLOWED_USERS[username] === password) {
                // Generate simple auth token
                const token = btoa(JSON.stringify({
                    username: username,
                    exp: Math.floor(Date.now() / 1000) + (24 * 3600)
                }));
                
                // Set cookie
                document.cookie = `auth_token=$${token}; path=/; max-age=86400; SameSite=Strict`;
                
                messageDiv.innerHTML = '<div style="color: green;">✅ Login successful! Redirecting...</div>';
                
                setTimeout(() => {
                    const urlParams = new URLSearchParams(window.location.search);
                    const redirectUrl = urlParams.get('redirect') || 'gallery.html';
                    window.location.href = redirectUrl;
                }, 1500);
            } else {
                messageDiv.innerHTML = '<div style="color: red;">❌ Invalid credentials</div>';
            }
        });
    </script>
</body>
</html>
EOT
}

resource "aws_s3_object" "gallery_html" {
  bucket       = aws_s3_bucket.pictures_website.id
  key          = "gallery.html"
  content_type = "text/html"
  content = <<-EOT
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Protected Gallery - Secure Pictures</title>
    <link rel="stylesheet" href="assets/styles.css">
</head>
<body>
    <div class="container">
        <h1>🖼️ Protected Gallery</h1>
        <div class="auth-indicator">
            ✅ You are authenticated! This page is protected by Lambda@Edge
        </div>
        
        <p>Welcome to the secure gallery! This content is only accessible to authenticated users.</p>
        
        <div id="imageGallery" class="gallery-grid">
            <div class="photo-item">
                <h3>Mountain Landscape</h3>
                <img src="https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800&h=600&fit=crop" alt="Mountain Landscape">
                <p>Breathtaking mountain vista with snow-capped peaks</p>
            </div>
            
            <div class="photo-item">
                <h3>Lake Sunset</h3>
                <img src="https://images.unsplash.com/photo-1439066615861-d1af74d74000?w=800&h=600&fit=crop" alt="Lake Sunset">
                <p>Serene lake reflecting the golden sunset</p>
            </div>
            
            <div class="photo-item">
                <h3>City Skyline</h3>
                <img src="https://images.unsplash.com/photo-1449824913935-59a10b8d2000?w=800&h=600&fit=crop" alt="City Skyline">
                <p>Modern urban skyline at dusk</p>
            </div>
            
            <div class="photo-item">
                <h3>Forest Path</h3>
                <img src="https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=800&h=600&fit=crop" alt="Forest Path">
                <p>Peaceful woodland trail surrounded by tall trees</p>
            </div>
            
            <div class="photo-item">
                <h3>Ocean Waves</h3>
                <img src="https://images.unsplash.com/photo-1506197603052-3cc9c3a201bd?w=800&h=600&fit=crop" alt="Ocean Waves">
                <p>Powerful ocean waves crashing on rocky shore</p>
            </div>
            
            <div class="photo-item">
                <h3>Desert Dunes</h3>
                <img src="https://images.unsplash.com/photo-1500534314209-a25ddb2bd429?w=800&h=600&fit=crop" alt="Desert Dunes">
                <p>Golden sand dunes stretching to the horizon</p>
            </div>
        </div>
        
        <p style="margin-top: 30px;">
            <a href="index.html" class="btn">← Back to Home</a>
            <button onclick="logout()" class="btn" style="background: #f44336;">🚪 Logout</button>
        </p>
    </div>

    <script>
        function logout() {
            document.cookie = 'auth_token=; path=/; max-age=0; SameSite=Strict';
            alert('You have been logged out');
            window.location.href = 'index.html';
        }
    </script>
</body>
</html>
EOT
}

resource "aws_s3_object" "styles_css" {
  bucket       = aws_s3_bucket.pictures_website.id
  key          = "assets/styles.css"
  content_type = "text/css"
  content = <<-EOT
/* Simplified CSS for Lambda@Edge Demo */
body { 
  font-family: Arial, sans-serif; 
  margin: 0; 
  padding: 20px; 
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  min-height: 100vh;
}
.container { 
  max-width: 1200px; 
  margin: 0 auto; 
  padding: 20px;
  background: rgba(255,255,255,0.1);
  border-radius: 10px;
}
.btn { 
  display: inline-block; 
  padding: 10px 20px; 
  background: #4CAF50; 
  color: white; 
  text-decoration: none; 
  border-radius: 5px; 
  margin: 10px;
}
.btn:hover { background: #45a049; }
.gallery-grid { 
  display: grid; 
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); 
  gap: 20px; 
  margin: 20px 0;
}
.photo-item { 
  background: rgba(255,255,255,0.1); 
  padding: 20px; 
  border-radius: 10px; 
  text-align: center;
}
.photo-item img { 
  max-width: 100%; 
  height: 200px; 
  object-fit: cover; 
  border-radius: 5px;
}
.login-box { 
  max-width: 400px; 
  margin: 50px auto; 
  background: rgba(255,255,255,0.9); 
  padding: 30px; 
  border-radius: 10px;
  color: #333;
}
.form-group { 
  margin: 15px 0; 
}
.form-group input { 
  width: 100%; 
  padding: 10px; 
  border: 1px solid #ddd; 
  border-radius: 5px;
  box-sizing: border-box;
}
.auth-indicator { 
  background: rgba(76, 175, 80, 0.2); 
  color: #4CAF50; 
  padding: 10px; 
  border-radius: 5px; 
  margin: 10px 0;
  text-align: center;
}
EOT
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