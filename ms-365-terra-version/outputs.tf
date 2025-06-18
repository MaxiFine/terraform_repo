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