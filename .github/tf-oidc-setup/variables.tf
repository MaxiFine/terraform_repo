# OIDC Setup Variables

variable "project_name" {
  description = "Name of the project (used for resource naming)"
  type        = string
  default     = "aws-startup-packages"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "github_org" {
  description = "GitHub organization name (e.g., 'YourOrg')"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name (e.g., 'aws-startup-packages')"
  type        = string
}

variable "branch" {
  description = "Main branch name that can deploy to production"
  type        = list(string)
  default     = ["main", "dev", "test"]
}

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "eu-west-1"
}

variable "use_admin_policy" {
  description = "Whether to attach AdministratorAccess policy (simpler but less secure)"
  type        = bool
  default     = true
}
