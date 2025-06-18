output "vpc_id" {
  description = "value for the VPC ID"
  value       = aws_vpc.mx-vpc.id
}

output "public_subnet_id" {
  description = "value for the public subnet ID"
  value       = aws_subnet.public_subnet.id

}

output "private_subnet_id" {
  description = "value for the private subnet ID"
  value       = aws_subnet.private_subnet.id
}

output "internet_gateway_id" {
  description = "value for the Internet Gateway ID"
  value       = aws_internet_gateway.mx-internet-gateway.id
}

output "nat_gateway_id" {
  description = "value for the NAT Gateway ID"
  value       = aws_nat_gateway.mx_nat_gateway.id
}

output "aws_region" {
  description = "The AWS region where the resources are deployed"
  value       = var.aws_region
}

output "aws_public_subnet" {
  description = "The public subnet ID"
  value       = aws_subnet.public_subnet.id
}

output "aws_private_subnet" {
  description = "The private subnet ID"
  value       = aws_subnet.private_subnet.id
}

output "mx_internet_gateway" {
  description = "The Internet Gateway ID"
#   value       = aws_internet_gateway.mx_internet_gateway.id
    value       = aws_internet_gateway.mx-internet-gateway.id
}