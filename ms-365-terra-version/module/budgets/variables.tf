# Parameters
variable "budget_name" {
  description = "Name of the budget"
  default     = "MxBudgetAlerts"
}

variable "budget_limit" {
  description = "Limit for the budget"
  default     = 5
}

variable "ec2_budget_limit" {
  description = "Limit for the EC2 budget"
  default     = 200
}

variable "notification_email" {
  description = "value for the email to receive notifications"
  default     = "maxwell.adomako@amalitech.com"
}

variable "project_tag" {
  description = "value for the project tag"
  default     = "Mx36TerraformVersion"
}

variable "ec2_tag_key" {
  description = "Key for the EC2 tag"
  default     = "Project"
}

variable "ec2_tag_value" {
  description = "Value for the EC2 tag"
  default     = "AWS-365"
}

variable "budget_tag_key" {
  default = "Project"
}
variable "budget_tag_value" {
  description = "Value for the budget tag"
  default     = "AWS-365"
}

variable "budget_notification_threshold" {
  description = "Threshold for budget notifications"
  default     = 80
}

# variable "sns_topic_arn" {
#   description = "ARN of the SNS topic for budget notifications"
#   type        = string

# }