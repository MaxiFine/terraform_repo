output "private_instance_ip_1" {
  description = "Private instance ip 1 address"
  value = aws_instance.aws_nat_gateway_instance[*].private_ip
}

output "private_instance_ip_2" {
  description = "Private instance ip 2 address"
  value = aws_instance.nat_testing_aws_instances[*].private_ip
}

