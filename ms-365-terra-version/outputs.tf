output "aws_region" {
  description = "The AWS region where the resources are deployed"
  value       = var.aws_region
  
}

output "public_subnet_id" {
  description = "The public subnet ID"
  value       = module.networking.public_subnet_id
  
}

output "private_subnet_id" {
  description = "The private subnet ID"
  value       = module.networking.private_subnet_id
  
}

output "vpc_id" {
  description = "The VPC ID"
  value       = module.networking.vpc_id
  
}

output "internet_gateway_id" {
  description = "The Internet Gateway ID"
  value       = module.networking.internet_gateway_id
  
}

output "nat_gateway_id" {
  description = "The NAT Gateway ID"
  value       = module.networking.nat_gateway_id
  
}

output "public_security_group_id" {
  description = "The ID of the public security group"
  value       = module.security_groups.public_security_group_id
  
}

output "private_security_group_id" {
  description = "The ID of the private security group"
  value       = module.security_groups.private_security_group_id

}

output "public_security_group_arn" {
  description = "The ARN of the public security group"
  value       = module.security_groups.public_security_group_arn
  
}

output "private_security_group_arn" {
  description = "The ARN of the private security group"
  value       = module.security_groups.private_security_group_arn

}

output "public_instance_id" {
  description = "The ID of the public EC2 instance"
  value       = module.compute.public_instance_id
}

# output "public_instance_public_ip" {
#   description = "The public IP address of the public EC2 instance"
#   value       = module.compute.public_instance_public_ip
# }

output "public_instance_arn" {
  description = "The ARN of the public EC2 instance"
  value       = module.compute.public_instance_arn
}

output "private_instance_id" {
  description = "The ID of the private EC2 instance"
  value       = module.compute.private_instance_id
}

output "private_instance_public_ip" {
  description = "The public IP address of the private EC2 instance"
  value       = module.compute.private_instance_public_ip
}

# output "private_instance_public_arn" {
#   description = "The public ARN of the private EC2 instance"
#   value       = module.compute.private_instance_public_arn
# }

output "name_of_sns_topic" {
  description = "The name of the SNS topic"
  value       = module.notifications.topic_name
  
}