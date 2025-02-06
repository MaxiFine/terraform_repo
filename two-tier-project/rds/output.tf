output "aws_db_instance" {
  description = "value of the rds instance id"
  value       = aws_db_instance.rds.id
  
}

output "aws_db_instance_address" {
  description = "value of the rds instance address"
  value       = aws_db_instance.rds.address
  
}

output "aws_db_instance_port" {
  description = "value of the rds instance port"
  value       = aws_db_instance.rds.port
  
}