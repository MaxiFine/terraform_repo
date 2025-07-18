# variable "queue_name" {
#   type        = string
#   default     = "AWS-365-SQSQueue"
#   description = "Name of the Queue"
# }

variable "topic_name" {
  type        = string
  default     = "Mx-SnsTopic"
  description = "Name of the SNS Topic"
}

variable "email_for_notifications" {
  type        = string
  default     = "gibboel5@gmail.com"
  description = "Email address to receive notifications"
}

variable "project_tag" {
  type    = string
  default = "Mx365|Project"
}

variable "notification_email" {
  type    = string
  default = "maxwell.adomako@amailtech.com"
}

# variable "department" {
#   type = string
# }

# variable "environment_name" {
#   type = string
# }

# variable "owner" {
#   type = string
# }

# variable "region_tag" {
#   type = string
# }

# variable "gl_account" {
#   type = string
# }

# variable "profit_center" {
#   type = string
# }

# variable "company_code" {
#   type = string
# }

# variable "cost_center" {
#   type = string
# }

# variable "sap_component" {
#   type = string
# }

# variable "billing_code" {
#   type = string
# }


