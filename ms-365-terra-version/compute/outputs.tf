output "instance_id" {
  description = "The ID of the EC2 instance"
  value       = aws_instance.public_instance.id
  
}

output "instance_public_ip" {
  description = "The public IP address of the EC2 instance"
  value       = aws_instance.public_instance.public_ip
}

output "public_instance_arn" {
  description = "The ARN of the public EC2 instance"
  value       = aws_instance.public_instance.arn
  
}

output "private_instance_id" {
  description = "The ID of the private EC2 instance"
  value       = aws_instance.public_instance.id
  
}

output "private_instance_public_ip" {
  description = "The public IP address of the private EC2 instance"
  value       = aws_instance.private_instance.public_ip
  
}