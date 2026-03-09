output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.website.id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.website.arn
}

output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.website.id
}

output "cloudfront_domain_name" {
  description = "Domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.website.domain_name
}

output "website_url" {
  description = "URL to access the website"
  value       = var.domain_name != "" ? "https://${var.domain_name}" : "https://${aws_cloudfront_distribution.website.domain_name}"
}

output "rum_app_monitor_id" {
  description = "CloudWatch RUM App Monitor ID"
  value       = var.enable_monitoring ? aws_rum_app_monitor.website[0].id : null
}

output "rum_identity_pool_id" {
  description = "CloudWatch RUM Cognito Identity Pool ID"
  value       = var.enable_monitoring ? aws_rum_app_monitor.website[0].app_monitor_configuration[0].identity_pool_id : null
}

output "cloudwatch_dashboard_url" {
  description = "CloudWatch Dashboard URL"
  value       = var.enable_monitoring ? "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${var.project_name}-${var.environment}" : null
}
