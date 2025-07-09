
locals {
  common_tags = {
    Project      = var.project_tag
    Department   = var.department
    Environment  = var.environment_name
  }
}

resource "aws_sns_topic" "sns_topic" {
  name         = var.topic_name
  display_name = "AWS-365 Topic"

  tags = merge(local.common_tags, {
    Name         = var.topic_name
    ResourceType = "SNS Topic"
  })
}

# resource "aws_sqs_queue" "sqs_queue" {
#   name = var.queue_name

#   tags = merge(local.common_tags, {
#     Name         = var.queue_name
#     ResourceType = "SQS Queue"
#   })
# }

# resource "aws_sqs_queue_policy" "sqs_queue_policy" {
#   queue_url = aws_sqs_queue.sqs_queue.url

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Id      = "AllowSendMessage"
#     Statement = [
#       {
#         Sid       = "AllowSendReceiveWithinAccount"
#         Effect    = "Allow"
#         Principal = { AWS = data.aws_caller_identity.current.account_id }
#         Action = [
#           "sqs:SendMessage",
#           "sqs:ReceiveMessage"
#         ]
#         Resource = aws_sqs_queue.sqs_queue.arn
#       },
#       {
#         Sid       = "AllowSNSTopicToSendMessage"
#         Effect    = "Allow"
#         Principal = "*"
#         Action    = "sqs:SendMessage"
#         Resource  = aws_sqs_queue.sqs_queue.arn
#         Condition = {
#           ArnEquals = {
#             "aws:SourceArn" = aws_sns_topic.sns_topic.arn
#           }
#         }
#       }
#     ]
#   })
# }

# resource "aws_sns_topic_subscription" "sqs_subscription" {
#   topic_arn = aws_sns_topic.sns_topic.arn
#   protocol  = "sqs"
#   endpoint  = aws_sqs_queue.sqs_queue.arn

#   depends_on = [aws_sqs_queue_policy.sqs_queue_policy]
# }

resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.sns_topic.arn
  protocol  = "email"
  endpoint  = var.email_for_notifications
}

data "aws_caller_identity" "current" {}

output "topic_arn" {
  value       = aws_sns_topic.sns_topic.arn
  description = "Topic Arn"
}

output "queue_url" {
  value       = aws_sqs_queue.sqs_queue.url
  description = "Queue URL"
}

output "queue_name" {
  value       = var.queue_name
  description = "Queue Name"
}
