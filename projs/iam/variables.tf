variable "environment" {
  type        = string
  description = "Deployment environment (develop, test, prod)"
}

variable "users" {
  type = map(object({
    username = string
    email    = string
    groups   = list(string)
  }))
  description = "Map of users to create with their details"
  default     = {}
}

variable "bedrock_models" {
  type        = list(string)
  description = "List of Bedrock model ARNs that users can access"
  default = [
    "arn:aws:bedrock:*::foundation-model/anthropic.claude-sonnet-4-*",
    "arn:aws:bedrock:*::foundation-model/anthropic.claude-opus-4-*",
    "arn:aws:bedrock:*::foundation-model/anthropic.claude-3-5-haiku-*"
  ]
}

variable "max_tokens_per_request" {
  type        = number
  description = "Maximum tokens per individual request"
  default     = 200000
}

variable "region" {
  type        = string
  description = "AWS region"
}