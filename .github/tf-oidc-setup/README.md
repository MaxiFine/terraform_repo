# OIDC Setup for GitHub Actions

Sets up OpenID Connect authentication for GitHub Actions to deploy AWS resources without storing access keys.

## Setup

1. Deploy the OIDC infrastructure:
```bash
cd .github/oidc-setup
terraform init
terraform apply -var="github_org=YOUR_ORG" -var="github_repo=YOUR_REPO -var="branch=dev"
```

2. Add the role ARN to GitHub secrets:
   - Go to repository Settings → Secrets and variables → Actions
   - Add secret: `AWS_DEPLOY_ROLE_ARN` with the role ARN from terraform output

3. Test by running any GitHub Actions workflow

## Configuration

Required variables:
- `github_org`: Your GitHub organization
- `github_repo`: Repository name
- `project_name`: Project name for resource naming

Optional:
- `environment`: Environment tag (default: "prod")
- `branch`: Allowed branch (default: "main")
- `aws_region`: AWS region (default: "eu-west-1")

## Resources Created

- GitHub OIDC Provider
- IAM Role with AdministratorAccess
- Trust policy allowing your GitHub repository

The role can only be assumed by the specified repository and branch.