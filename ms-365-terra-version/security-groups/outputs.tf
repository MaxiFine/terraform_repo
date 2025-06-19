output "public_security_group_id" {
  description = "The ID of the public security group"
  value       = module.security_groups.public_security_group.id
  
}

output "private_security_group_id" {
  description = "The ID of the private security group"
  value       = module.security_groups.private_security_group.id
}

output "public_security_group_arn" {
  description = "The name of the public security group"
  value       = module.security_groups.public_security_group.arn
  
}
output "private_security_group_arn" {
  description = "The name of the private security group"
  value       = module.security_groups.private_security_group.arn
}