output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.ecs_vpc.id
}

output "security_group_id" {
  description = "The ID of the security group"
  value       = aws_security_group.ecs_security_group.id
}

output "subnet1" {
    description = "The ID of the first subnet"
    value       = aws_subnet.ecs_subnet_1.id
}

output "subnet2" {
    description = "The ID of the second subnet"
    value       = aws_subnet.ecs_subnet_2.id
}

output "IGW_id" {
    description = "The ID of the Internet Gateway"
    value       = aws_internet_gateway.ecs_igw.id
  
}