# GitHub OIDC Setup (CloudFormation)

This guide explains how to deploy `.github/cf-oidc-setup/github-oidc-roles.yml` so GitHub Actions can assume AWS roles without long-lived access keys.

## What This Creates

- Optional GitHub OIDC provider: `token.actions.githubusercontent.com`
- Deploy role ARN output: `AWSDeployRoleArn`
- Destroy role ARN output: `AWSDestroyRoleArn`
- Custom managed policy for pipeline operations
- Optional `AdministratorAccess` attachment for quick testing

## Prerequisites

- AWS CLI configured with permissions to create IAM resources and CloudFormation stacks.
- GitHub repository with workflows using OIDC (`id-token: write`).
- Your GitHub org/user and repo name.

## Deploy

Run from repository root:

```bash
aws cloudformation deploy \
  --template-file .github/cf-oidc-setup/github-oidc-roles.yml \
  --stack-name aws365-github-oidc-roles \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    ProjectName=aws-365 \
    Environment=dev \
    GitHubOrg=YOUR_GITHUB_ORG \
    GitHubRepo=AWS-365 \
    DeployBranch1=main \
    DeployBranch2=dev \
    DeployBranch3=test \
    DeployBranch4=auto \
    DestroyBranch=main \
    CreateOIDCProvider=true \
    UseAdminPolicy=true
```

Notes:
- Use `CreateOIDCProvider=true` only the first time in an AWS account.
- After provider exists, use `CreateOIDCProvider=false` on updates.
- Use `UseAdminPolicy=false` when you move to least-privilege.

## Get Role ARNs

```bash
aws cloudformation describe-stacks \
  --stack-name aws365-github-oidc-roles \
  --query "Stacks[0].Outputs[].[OutputKey,OutputValue]" \
  --output table
```

Copy these outputs:
- `AWSDeployRoleArn`
- `AWSDestroyRoleArn`

## Configure GitHub Secrets

In your GitHub repo:
`Settings` -> `Secrets and variables` -> `Actions` -> `New repository secret`

Add:
- `AWS_DEPLOY_ROLE_ARN` = `AWSDeployRoleArn`
- `AWS_DESTROY_ROLE_ARN` = `AWSDestroyRoleArn`
- `AWS_REGION` = deployment region (example: `eu-west-1`)
- Keep existing budget secrets used by deploy workflow:
  - `AWS_BUDGET_REGION`
  - `AWS_BUDGET_LIMIT`
  - `AWS_BUDGET_EMAIL`

## Verify OIDC Provider Exists

```bash
aws iam list-open-id-connect-providers
aws iam get-open-id-connect-provider \
  --open-id-connect-provider-arn arn:aws:iam::<ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com
```

## Test Workflows

1. Run `deploy.yml` (push to allowed branch or `workflow_dispatch`).
2. Confirm step `Configure AWS Credentials` succeeds.
3. Run `destroy.yml` manually and verify stack deletion completes.

## Common Errors

- `No OpenIDConnect provider found for https://token.actions.githubusercontent.com`
Cause: provider does not exist in that account.
Fix: deploy stack with `CreateOIDCProvider=true`.

- `Not authorized to perform sts:AssumeRoleWithWebIdentity`
Cause: trust policy subject/branch mismatch.
Fix: ensure `GitHubOrg`, `GitHubRepo`, and allowed branch parameters match the workflow trigger branch.

- Role assumption still fails after updates
Cause: wrong role ARN in GitHub secrets or wrong AWS account.
Fix: re-copy stack outputs and confirm provider and roles exist in the same account.
