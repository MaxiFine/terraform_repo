variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "learning"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "lambda-edge-demo"
}

variable "enable_logging" {
  description = "Enable CloudFront logging"
  type        = bool
  default     = false
}

variable "price_class" {
  description = "CloudFront price class"
  type        = string
  default     = "PriceClass_100"
  
  validation {
    condition     = contains(["PriceClass_All", "PriceClass_200", "PriceClass_100"], var.price_class)
    error_message = "Price class must be PriceClass_All, PriceClass_200, or PriceClass_100."
  }
}

variable "ab_test_percentage" {
  description = "Percentage of traffic to route to version B (0-100)"
  type        = number
  default     = 50
  
  validation {
    condition     = var.ab_test_percentage >= 0 && var.ab_test_percentage <= 100
    error_message = "A/B test percentage must be between 0 and 100."
  }
}