output "public_security_group_id" {
  description = "The ID of the public security group"
  value       = aws_security_group.public_sg.id

}

output "private_security_group_id" {
  description = "The ID of the private security group"
  value       = aws_security_group.private_sg.id
}

output "public_security_group_arn" {
  description = "The ARN of the public security group"
  value       = aws_security_group.public_sg.arn
  
}
output "private_security_group_arn" {
  description = "The ARN of the private security group"
  value       = aws_security_group.private_sg.arn
}