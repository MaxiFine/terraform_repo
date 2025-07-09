
# locals {
#   common_tags = {
#     Project      = "Mx365Project"
#     Department   = "DevOps"
#     Environment  = "Development"
#   }
# }

resource "aws_sns_topic" "sns_topic" {
  name         = var.topic_name
  display_name = "Mx-SnsTopic"

  tags = {
    Project      = "Mx365Project"
    Environment  = "Development"
    ResourceType = "SNS Topic"
  }

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

# data "aws_caller_identity" "current" {}

