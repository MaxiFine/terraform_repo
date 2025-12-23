output "private_instance_ip_1" {
  description = "Private instance ip 1 address"
  value = aws_instance.nat_aws_instances.private_ip
}

output "private_instance_ip_2" {
  description = "Private instance ip 2 address"
  value = aws_instance.test_instance.private_ip
}

