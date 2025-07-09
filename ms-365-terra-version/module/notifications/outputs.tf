output "topic_arn" {
  value       = aws_sns_topic.sns_topic.arn
  description = "Topic Arn"
}

# output "queue_url" {
#   value       = aws_sqs_queue.sqs_queue.url
#   description = "Queue URL"
# }

output "topic_name" {
  value       = aws_sns_topic.sns_topic.name
  description = "Topic Name"
  
}


