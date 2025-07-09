# Parameters
variable "budget_name" {
  default = "AWS365BudgetAlerts"
}

variable "budget_limit" {
  default = 5
}

variable "ec2_budget_limit" {
  default = 200
}

variable "notification_email" {
  default = "maxwell.adomako@amalitech.com"
}

variable "project_tag" {
  default = "AWS-365"
}

variable "ec2_tag_key" {
  default = "Project"
}

variable "ec2_tag_value" {
  default = "AWS-365"
}

variable "budget_tag_key" {
  default = "Project"
}
variable "budget_tag_value" {
  default = "AWS-365"
}

variable "budget_notification_threshold" {
  default = 80
}

