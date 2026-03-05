# OIDC Setup for AWS Startup Packages GitHub Actions
# This sets up the OpenID Connect provider and IAM role for secure authentication

# Get current AWS partition info
data "aws_partition" "current" {}

# ==============================================================================
# GITHUB OIDC PROVIDER
# ==============================================================================

# Create GitHub OIDC Provider (only needed once per AWS account)
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]

  tags = {
    Name      = "GitHub-OIDC-Provider"
    Purpose   = "AWS-Startup-Packages-CI-CD"
    ManagedBy = "Terraform"
  }
}

# ==============================================================================
# IAM ROLE FOR GITHUB ACTIONS
# ==============================================================================

# Trust policy allowing GitHub Actions to assume the role
data "aws_iam_policy_document" "github_actions_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/${var.branch}",
        "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/main",
        "repo:${var.github_org}/${var.github_repo}:pull_request"
      ]
    }
  }
}

# IAM Role for GitHub Actions
resource "aws_iam_role" "github_actions_deploy_role" {
  name               = "${var.project_name}-GitHubActionsDeployRole"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role.json
  description        = "Role assumed by GitHub Actions via OIDC for deploying AWS Startup Packages"

  tags = {
    Name        = "${var.project_name}-GitHubActionsDeployRole"
    Purpose     = "AWS-Startup-Packages-CI-CD"
    ManagedBy   = "Terraform"
    Environment = var.environment
  }
}

# ==============================================================================
# IAM POLICIES FOR DEPLOYMENT
# ==============================================================================

# Custom policy for startup packages deployment
data "aws_iam_policy_document" "github_actions_deployment_policy" {
  # Terraform state management (S3 & DynamoDB)
  statement {
    sid    = "TerraformStateManagement"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket",
      "s3:GetBucketVersioning",
      "s3:GetBucketLocation",
      "s3:CreateBucket",
      "s3:PutBucketVersioning",
      "s3:PutBucketEncryption",
      "s3:PutBucketPublicAccessBlock"
    ]
    resources = ["*"]
  }

  # EC2 and VPC management
  statement {
    sid    = "EC2AndVPCManagement"
    effect = "Allow"
    actions = [
      "ec2:*",
      "vpc:*"
    ]
    resources = ["*"]
  }

  # S3 management for modules
  statement {
    sid    = "S3Management"
    effect = "Allow"
    actions = [
      "s3:*"
    ]
    resources = ["*"]
  }

  # RDS management
  statement {
    sid    = "RDSManagement"
    effect = "Allow"
    actions = [
      "rds:*"
    ]
    resources = ["*"]
  }

  # Lambda and EventBridge
  statement {
    sid    = "LambdaAndEventBridge"
    effect = "Allow"
    actions = [
      "lambda:*",
      "events:*"
    ]
    resources = ["*"]
  }

  # IAM for resource creation (limited)
  statement {
    sid    = "IAMForResources"
    effect = "Allow"
    actions = [
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:PutRolePolicy",
      "iam:DeleteRolePolicy",
      "iam:GetRole",
      "iam:GetRolePolicy",
      "iam:ListRolePolicies",
      "iam:ListAttachedRolePolicies",
      "iam:CreateInstanceProfile",
      "iam:DeleteInstanceProfile",
      "iam:AddRoleToInstanceProfile",
      "iam:RemoveRoleFromInstanceProfile",
      "iam:ListInstanceProfiles",
      "iam:PassRole"
    ]
    resources = ["*"]
  }

  # KMS for encryption
  statement {
    sid    = "KMSManagement"
    effect = "Allow"
    actions = [
      "kms:*"
    ]
    resources = ["*"]
  }

  # SNS for notifications
  statement {
    sid    = "SNSManagement"
    effect = "Allow"
    actions = [
      "sns:*"
    ]
    resources = ["*"]
  }

  # CloudTrail and Config (for security modules)
  statement {
    sid    = "SecurityServices"
    effect = "Allow"
    actions = [
      "cloudtrail:*",
      "config:*",
      "guardduty:*"
    ]
    resources = ["*"]
  }

  # Organizations (for SCP modules)
  statement {
    sid    = "OrganizationsManagement"
    effect = "Allow"
    actions = [
      "organizations:*"
    ]
    resources = ["*"]
  }

  # General read permissions
  statement {
    sid    = "GeneralReadPermissions"
    effect = "Allow"
    actions = [
      "sts:GetCallerIdentity",
      "account:ListRegions"
    ]
    resources = ["*"]
  }
}

# Create the deployment policy
resource "aws_iam_policy" "github_actions_deployment_policy" {
  name        = "${var.project_name}-GitHubActionsDeploymentPolicy"
  description = "Policy for GitHub Actions to deploy AWS Startup Packages"
  policy      = data.aws_iam_policy_document.github_actions_deployment_policy.json

  tags = {
    Name        = "${var.project_name}-GitHubActionsDeploymentPolicy"
    Purpose     = "AWS-Startup-Packages-CI-CD"
    ManagedBy   = "Terraform"
    Environment = var.environment
  }
}

# Attach the deployment policy to the role
resource "aws_iam_role_policy_attachment" "github_actions_deployment_policy" {
  role       = aws_iam_role.github_actions_deploy_role.name
  policy_arn = aws_iam_policy.github_actions_deployment_policy.arn
}

# Optional: Attach AdministratorAccess for full permissions (less secure but simpler)
resource "aws_iam_role_policy_attachment" "github_actions_admin_policy" {
  count      = var.use_admin_policy ? 1 : 0
  role       = aws_iam_role.github_actions_deploy_role.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AdministratorAccess"
}
