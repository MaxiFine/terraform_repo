output "vpc_id" {
    description = "value for the VPC ID"
    value       = aws_vpc.vpc.id
}

output "public_subnet_id" {
    description = "value for the public subnet ID"
    value       = aws_subnet.public_subnet.id
  
}

output "private_subnet_id" {
    description = "value for the private subnet ID"
    value       = aws_subnet.private_subnet.id
}