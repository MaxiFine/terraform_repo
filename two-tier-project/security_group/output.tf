output "aws_security_group" {
  description = "value of the web security group id"
  value       = aws_security_group.web_sg.id
  
}

output "aws_security_group" {
  description = "value of the rds security group id"
  value       = aws_security_group.rds_sg.id
  
}