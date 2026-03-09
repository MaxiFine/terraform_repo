# CloudWatch RUM App Monitor
resource "aws_rum_app_monitor" "website" {
  count  = var.enable_monitoring ? 1 : 0
  name   = "${var.project_name}-${var.environment}"
  domain = var.domain_name != "" ? var.domain_name : aws_cloudfront_distribution.website.domain_name

  app_monitor_configuration {
    allow_cookies      = true
    enable_xray        = true
    session_sample_rate = 1.0
    telemetries        = ["errors", "performance", "http"]

    favorite_pages = ["/"]
  }
}

# CloudWatch Log Group for RUM
resource "aws_cloudwatch_log_group" "rum" {
  count             = var.enable_monitoring ? 1 : 0
  name              = "/aws/rum/${var.project_name}-${var.environment}"
  retention_in_days = 7
}

# CloudWatch Alarms for CloudFront
resource "aws_cloudwatch_metric_alarm" "cloudfront_error_rate" {
  count               = var.enable_monitoring ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-high-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "5xxErrorRate"
  namespace           = "AWS/CloudFront"
  period              = 300
  statistic           = "Average"
  threshold           = 5
  alarm_description   = "CloudFront 5xx error rate is above 5%"
  treat_missing_data  = "notBreaching"

  dimensions = {
    DistributionId = aws_cloudfront_distribution.website.id
  }
}

resource "aws_cloudwatch_metric_alarm" "cloudfront_requests" {
  count               = var.enable_monitoring ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-low-requests"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Requests"
  namespace           = "AWS/CloudFront"
  period              = 3600
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "No requests in the last hour - possible outage"
  treat_missing_data  = "breaching"

  dimensions = {
    DistributionId = aws_cloudfront_distribution.website.id
  }
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "website" {
  count          = var.enable_monitoring ? 1 : 0
  dashboard_name = "${var.project_name}-${var.environment}"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/CloudFront", "Requests", { stat = "Sum", label = "Total Requests" }],
            [".", "BytesDownloaded", { stat = "Sum", label = "Bytes Downloaded" }]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "CloudFront Traffic"
          dimensions = {
            DistributionId = aws_cloudfront_distribution.website.id
          }
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/CloudFront", "4xxErrorRate", { stat = "Average", label = "4xx Error Rate" }],
            [".", "5xxErrorRate", { stat = "Average", label = "5xx Error Rate" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "Error Rates"
          yAxis = {
            left = {
              min = 0
            }
          }
          dimensions = {
            DistributionId = aws_cloudfront_distribution.website.id
          }
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/CloudFront", "CacheHitRate", { stat = "Average", label = "Cache Hit Rate" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "Cache Performance"
          yAxis = {
            left = {
              min = 0
              max = 100
            }
          }
          dimensions = {
            DistributionId = aws_cloudfront_distribution.website.id
          }
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/S3", "BucketSizeBytes", { stat = "Average", label = "Bucket Size" }],
            [".", "NumberOfObjects", { stat = "Average", label = "Object Count" }]
          ]
          period = 86400
          stat   = "Average"
          region = var.aws_region
          title  = "S3 Storage"
          dimensions = {
            BucketName = aws_s3_bucket.website.id
            StorageType = "StandardStorage"
          }
        }
      }
    ]
  })
}

# S3 Bucket Metrics
resource "aws_s3_bucket_metric" "website" {
  count  = var.enable_monitoring ? 1 : 0
  bucket = aws_s3_bucket.website.id
  name   = "EntireBucket"
}

# CloudWatch Log Group for CloudFront (optional)
resource "aws_cloudwatch_log_group" "cloudfront" {
  count             = var.enable_monitoring ? 1 : 0
  name              = "/aws/cloudfront/${var.project_name}-${var.environment}"
  retention_in_days = 7
}
