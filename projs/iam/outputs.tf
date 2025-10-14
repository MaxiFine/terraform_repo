output "bedrock_users_group_name" {
  description = "Name of the Bedrock users IAM group"
  value       = aws_iam_group.bedrock_users.name
}

output "bedrock_admins_group_name" {
  description = "Name of the Bedrock admins IAM group"
  value       = aws_iam_group.bedrock_admins.name
}

output "bedrock_user_policy_arn" {
  description = "ARN of the Bedrock user policy"
  value       = aws_iam_policy.bedrock_user_policy.arn
}

output "bedrock_admin_policy_arn" {
  description = "ARN of the Bedrock admin policy"
  value       = aws_iam_policy.bedrock_admin_policy.arn
}

output "user_access_keys" {
  description = "Access keys for Claude Code users (sensitive)"
  value = {
    for k, v in aws_iam_access_key.user_keys : k => {
      access_key_id     = v.id
      secret_access_key = v.secret
    }
  }
  sensitive = true
}

output "user_arns" {
  description = "ARNs of created IAM users"
  value       = { for k, v in aws_iam_user.bedrock_users : k => v.arn }
}

output "claude_code_instance_role_arn" {
  description = "ARN of the IAM role for Claude Code EC2 instances"
  value       = aws_iam_role.claude_code_instance_role.arn
}

output "claude_code_instance_profile_name" {
  description = "Name of the instance profile for Claude Code EC2 instances"
  value       = aws_iam_instance_profile.claude_code_instance_profile.name
}