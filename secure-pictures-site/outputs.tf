output "cloudfront_distribution_id" {
  description = "CloudFront Distribution ID"
  value       = aws_cloudfront_distribution.pictures_website_cdn.id
}

output "cloudfront_domain_name" {
  description = "CloudFront Distribution Domain Name"
  value       = aws_cloudfront_distribution.pictures_website_cdn.domain_name
}

output "website_url" {
  description = "Website URL"
  value       = "https://${aws_cloudfront_distribution.pictures_website_cdn.domain_name}"
}

output "gallery_url" {
  description = "Protected Gallery URL (requires authentication)"
  value       = "https://${aws_cloudfront_distribution.pictures_website_cdn.domain_name}/gallery.html"
}

output "login_url" {
  description = "Login Page URL"
  value       = "https://${aws_cloudfront_distribution.pictures_website_cdn.domain_name}/login.html"
}

output "s3_bucket_name" {
  description = "S3 Bucket Name"
  value       = aws_s3_bucket.pictures_website.id
}

output "test_credentials" {
  description = "Demo login credentials for testing"
  value = {
    demo_user = {
      username = "demo"
      password = "password123"
    }
    admin_user = {
      username = "admin" 
      password = "admin123"
    }
  }
}

output "testing_instructions" {
  description = "Instructions for testing the authentication"
  value = <<-EOT
    1. Visit the homepage: https://${aws_cloudfront_distribution.pictures_website_cdn.domain_name}
    2. Try to access gallery directly: https://${aws_cloudfront_distribution.pictures_website_cdn.domain_name}/gallery.html
    3. You should be redirected to login page
    4. Login with credentials:
       - Username: demo
       - Password: password123
    5. After login, you should be able to access the gallery
    
    Test commands:
    # Try accessing gallery without auth (should redirect to login)
    curl -I "https://${aws_cloudfront_distribution.pictures_website_cdn.domain_name}/gallery.html"
    
    # Try accessing an image directly (should be blocked)
    curl -I "https://${aws_cloudfront_distribution.pictures_website_cdn.domain_name}/data/images.json"
  EOT
}

output "lambda_function_arns" {
  description = "Lambda@Edge function ARNs"
  value = {
    auth_function           = aws_lambda_function.auth_function.qualified_arn
    security_headers_function = aws_lambda_function.security_headers_function.qualified_arn
  }
}