output "aws_vpc_main" {
  description = "value of the vpc main"
  value       = aws_vpc.main
  
}

output "vpc_id" {
  description = "value of the vpc id"
  value       = aws_vpc.main.id
  
}

output "vpc_cidr" {
  description = "value of the vpc name"
  value       = aws_vpc.main.tags.Name
  
}

# output "aws_vpc_main" {
#   description = "value of the vpc main"
#   value       = aws_vpc.main
  
# }

output "aws_subnet_ids" {
  description = "value of the subnet ids"
  value       = aws_subnet.public_subnets[*].id
  
}

output "public_subnet_cidrs" {
  description = "value of the public subnet cidrs"
  value       = aws_subnet.public_subnets[*].cidr_block
  
}

output "private_subnet_cidrs" {
  description = "value of the private subnet cidrs"
  value       = aws_subnet.private_subnets[*].cidr_block
  
}

output "aws_internet_gateway_id" {
  description = "value of the internet gateway id"
  value       = aws_internet_gateway.igw.id
  
}