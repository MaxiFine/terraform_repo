output "cloudfront_distribution_id" {
  description = "CloudFront Distribution ID"
  value       = aws_cloudfront_distribution.website_distribution.id
}

output "cloudfront_domain_name" {
  description = "CloudFront Distribution Domain Name"
  value       = aws_cloudfront_distribution.website_distribution.domain_name
}

output "cloudfront_url" {
  description = "CloudFront Distribution URL"
  value       = "https://${aws_cloudfront_distribution.website_distribution.domain_name}"
}

output "s3_bucket_name" {
  description = "S3 Bucket Name"
  value       = aws_s3_bucket.website_bucket.id
}

output "s3_website_endpoint" {
  description = "S3 Website Endpoint"
  value       = aws_s3_bucket_website_configuration.website_bucket_config.website_endpoint
}

output "lambda_security_headers_arn" {
  description = "Security Headers Lambda@Edge Function ARN"
  value       = aws_lambda_function.security_headers.qualified_arn
}

output "lambda_ab_testing_arn" {
  description = "A/B Testing Lambda@Edge Function ARN"
  value       = aws_lambda_function.ab_testing.qualified_arn
}

output "test_commands" {
  description = "Commands to test your Lambda@Edge setup"
  value = <<-EOT
    # Test the website:
    curl -I https://${aws_cloudfront_distribution.website_distribution.domain_name}
    
    # Test A/B testing (run multiple times to see different versions):
    curl https://${aws_cloudfront_distribution.website_distribution.domain_name}
    
    # Check security headers:
    curl -I https://${aws_cloudfront_distribution.website_distribution.domain_name} | grep -E "(X-|Strict|Content-Security)"
    
    # Test from different locations (if you have access):
    curl -H "CloudFront-Viewer-Country: US" https://${aws_cloudfront_distribution.website_distribution.domain_name}
    curl -H "CloudFront-Viewer-Country: GB" https://${aws_cloudfront_distribution.website_distribution.domain_name}
  EOT
}