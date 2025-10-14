# IAM Module for Bedrock User Management
# Implements enterprise security controls for Claude Code and Bedrock access

# IAM Group for Bedrock Users
resource "aws_iam_group" "bedrock_users" {
  name = "bedrock-users-${var.environment}"
  path = "/"
}

# IAM Group for Bedrock Administrators
resource "aws_iam_group" "bedrock_admins" {
  name = "bedrock-admins-${var.environment}"
  path = "/"
}

# Policy for basic Bedrock access
resource "aws_iam_policy" "bedrock_user_policy" {
  name        = "BedrockUserPolicy-${var.environment}"
  description = "Policy for basic Bedrock model access with usage tracking"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream"
        ]
        Resource = var.bedrock_models
        Condition = {
          StringEquals = {
            "bedrock:MaxTokens" = var.max_tokens_per_request
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "bedrock:GetFoundationModel",
          "bedrock:ListFoundationModels"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          "arn:aws:logs:${var.region}:*:log-group:/aws/bedrock/${var.environment}",
          "arn:aws:logs:${var.region}:*:log-group:/aws/bedrock/${var.environment}:*"
        ]
      }
    ]
  })

  tags = {
    Environment = var.environment
    Service     = "bedrock"
    Purpose     = "user-access"
  }
}

# Policy for Bedrock administrators
resource "aws_iam_policy" "bedrock_admin_policy" {
  name        = "BedrockAdminPolicy-${var.environment}"
  description = "Policy for Bedrock administrators with full access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "bedrock:*"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:*"
        ]
        Resource = [
          "arn:aws:logs:${var.region}:*:log-group:/aws/bedrock/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:*"
        ]
        Resource = "*"
        Condition = {
          StringLike = {
            "cloudwatch:namespace" = "AWS/Bedrock"
          }
        }
      }
    ]
  })

  tags = {
    Environment = var.environment
    Service     = "bedrock"
    Purpose     = "admin-access"
  }
}

# Attach policies to groups
resource "aws_iam_group_policy_attachment" "bedrock_users_policy" {
  group      = aws_iam_group.bedrock_users.name
  policy_arn = aws_iam_policy.bedrock_user_policy.arn
}

resource "aws_iam_group_policy_attachment" "bedrock_admins_policy" {
  group      = aws_iam_group.bedrock_admins.name
  policy_arn = aws_iam_policy.bedrock_admin_policy.arn
}

# Create IAM users
resource "aws_iam_user" "bedrock_users" {
  for_each = var.users

  name = each.value.username
  path = "/"

  tags = {
    Environment = var.environment
    Service     = "bedrock"
    Email       = each.value.email
    User        = each.key
  }
}

# Add users to appropriate groups
resource "aws_iam_user_group_membership" "user_groups" {
  for_each = var.users

  user   = aws_iam_user.bedrock_users[each.key].name
  groups = each.value.groups
}

# Create access keys for Claude Code CLI access
resource "aws_iam_access_key" "user_keys" {
  for_each = var.users
  user     = aws_iam_user.bedrock_users[each.key].name
}

# Role for EC2 instances running Claude Code
resource "aws_iam_role" "claude_code_instance_role" {
  name = "claude-code-instance-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Environment = var.environment
    Service     = "bedrock"
    Purpose     = "claude-code-instance"
  }
}

# Instance profile for EC2
resource "aws_iam_instance_profile" "claude_code_instance_profile" {
  name = "claude-code-instance-profile-${var.environment}"
  role = aws_iam_role.claude_code_instance_role.name
}

# Attach Bedrock policy to EC2 role
resource "aws_iam_role_policy_attachment" "claude_code_instance_policy" {
  role       = aws_iam_role.claude_code_instance_role.name
  policy_arn = aws_iam_policy.bedrock_user_policy.arn
}