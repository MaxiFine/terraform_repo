variable "aws_region" {
  description = "The AWS region where the resources will be deployed."
  type        = string
  # default     = "eu-north-1"  
  default     = "eu-west-1"  # using eu-west-1 for to comply scp
}

variable "email_for_notifications" {
  description = "Email address to receive notifications."
  type        = string
  # default     = "gibboel5@gmail.com"
  default = "maxwell.adomako@amalitech.com"
}