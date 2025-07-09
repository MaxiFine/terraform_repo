provider "aws" {
  region = "us-east-1"
}


# SNS Topic
resource "aws_sns_topic" "budget_alerts" {
  name         = "Mx365BudgetNotificationTopic"
  display_name = "Mx365 Budget Alerts"
  tags = {
    Name    = "MxBudgetNotificationTopic"
    Project = var.project_tag
  }
}

# SNS Email Subscription
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.budget_alerts.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

# SNS Policy to allow Budgets to publish
resource "aws_sns_topic_policy" "budget_policy" {
  arn    = aws_sns_topic.budget_alerts.arn
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowBudgetsToPublish"
        Effect    = "Allow"
        Principal = {
          Service = "budgets.amazonaws.com"
        }
        Action   = "sns:Publish"
        Resource = aws_sns_topic.budget_alerts.arn
      }
    ]
  })
}

# Main Budget
resource "aws_budgets_budget" "monthly_budget" {
  name              = var.budget_name
  budget_type       = "COST"
  time_unit         = "MONTHLY"
  limit_amount      = var.budget_limit
  limit_unit        = "USD"

  cost_types {
    include_upfront            = true
    include_recurring          = true
    include_other_subscription = true
    include_refund             = false
    include_credit             = false
    include_support            = true
    include_tax                = true
    use_blended                = false
    use_amortized              = false
  }

  notification {
    comparison_operator = "GREATER_THAN"
    notification_type   = "ACTUAL"
    threshold           = 50
    threshold_type      = "PERCENTAGE"

    subscriber {
      address          = aws_sns_topic.budget_alerts.arn
      subscription_type = "SNS"
    }
  }

  notification {
    comparison_operator = "GREATER_THAN"
    notification_type   = "ACTUAL"
    threshold           = 70
    threshold_type      = "PERCENTAGE"

    subscriber {
      address          = aws_sns_topic.budget_alerts.arn
      subscription_type = "SNS"
    }
  }

  notification {
    comparison_operator = "GREATER_THAN"
    notification_type   = "FORECASTED"
    threshold           = 90
    threshold_type      = "PERCENTAGE"

    subscriber {
      address          = aws_sns_topic.budget_alerts.arn
      subscription_type = "SNS"
    }
  }
}

# EC2 Filtered Budget
resource "aws_budgets_budget" "ec2_budget" {
  name              = "${var.budget_name}-EC2InstanceUsage"
  budget_type       = "COST"
  time_unit         = "MONTHLY"
  limit_amount      = var.ec2_budget_limit
  limit_unit        = "USD"

  cost_filters = {
    Service       = "Amazon Elastic Compute Cloud - Compute"
    TagKeyValue   = "${var.ec2_tag_key}$${var.ec2_tag_value}"
  }

  cost_types {
    include_upfront            = true
    include_recurring          = true
    include_other_subscription = true
    include_refund             = false
    include_credit             = false
    include_support            = true
    include_tax                = true
    use_blended                = false
    use_amortized              = false
  }

  notification {
    comparison_operator = "GREATER_THAN"
    notification_type   = "ACTUAL"
    threshold           = 50
    threshold_type      = "PERCENTAGE"

    subscriber_sns_arns    = [aws_sns_topic.budget_alerts.arn]
    
  # subscriber {
  #     address          = aws_sns_topic.budget_alerts.arn
  #     subscription_type = "SNS"
  #   }
  }

  notification {
    comparison_operator = "GREATER_THAN"
    notification_type   = "ACTUAL"
    threshold           = 80
    threshold_type      = "PERCENTAGE"

    subscriber {
      address          = aws_sns_topic.budget_alerts.arn
      subscription_type = "SNS"
    }
  }
}
