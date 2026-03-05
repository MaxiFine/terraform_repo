output "github_actions_role_arn" {
  description = "Add this to GitHub secrets as AWS_DEPLOY_ROLE_ARN"
  value       = aws_iam_role.github_actions_deploy_role.arn
}

output "github_oidc_provider_arn" {
  description = "GitHub OIDC provider ARN"
  value       = aws_iam_openid_connect_provider.github.arn
}
