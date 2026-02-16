output "nat_instance_id" {
    value       = aws_instance.nat_ec2_instance.id
    description = "ID of the NAT EC2 instance"
}

output "nat_instance_eip" {
    value       = aws_eip.nat_ec2_eip.public_ip
    description = "Elastic IP associated with NAT EC2"
}

output "private_test_instance_id" {
    value       = aws_instance.private_test_ec2.id
    description = "ID of the private test EC2"
}
