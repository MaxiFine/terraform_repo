output "vpc_id" {
  description = "VPC ID"
  value = aws_vpc.main.id
}

output "private_subnets" {
    description = "Private Subnets"
    # type = list(string)
    value = [aws_subnet.private.*.id]
}


output "route_table_id" {
    description = "Route Table ID"
    value = aws_route_table.private.id  
}

