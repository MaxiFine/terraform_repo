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

output "instance_id" {
  description = "Private EC2 Instance ID (use this for SSM connection)"
  value = aws_instance.private.id
}

output "ssm_connection_command" {
  description = "Command to connect via SSM"
  value = "aws ssm start-session --target ${aws_instance.private.id} --region ${var.region}"
}

output "check_ssm_status" {
  description = "Command to verify SSM agent status"
  value = "aws ssm describe-instance-information --filters Key=InstanceIds,Values=${aws_instance.private.id} --region ${var.region}"
}

