output "ec2_instance_id" {
  description = "value of the ec2 instance id"
  value       = aws_instance.ec2_instance.id
  
}

output "ec2_instance_public_ip" {
  description = "value of the ec2 instance public ip"
  value       = aws_instance.ec2_instance.public_ip

}

output "ec2_instance_private_ip" {
  description = "value of the ec2 instance private ip"
  value       = aws_instance.ec2_instance.private_ip

}

output "ec2_instance_availability_zone" {
  description = "value of the ec2 instance availability zone"
  value       = aws_instance.ec2_instance.availability_zone

}

output "ec2_instance_key_name" {
  description = "value of the ec2 instance key name"
  value       = aws_instance.ec2_instance.key_name

}

output "ec2_instance_security_group" {
  description = "value of the ec2 instance security group"
  value       = aws_instance.ec2_instance.security_groups

}   

output "ec2_instance_subnet_id" {
  description = "value of the ec2 instance subnet id"
  value       = aws_instance.ec2_instance.subnet_id

}

output "ec2_instance_vpc_security_group_ids" {
  description = "value of the ec2 instance vpc security group ids"
  value       = aws_instance.ec2_instance.vpc_security_group_ids

}

output "ec2_instance_tags" {
  description = "value of the ec2 instance tags"
  value       = aws_instance.ec2_instance.tags

}

output "ec2_instance_arn" {
  description = "value of the ec2 instance arn"
  value       = aws_instance.ec2_instance.arn

}

output "ec2_instance_network_interface_id" {
  description = "value of the ec2 instance network interface id"
  value       = aws_instance.ec2_instance.network_interface_ids

}

output "ec2_instance_private_dns" {
  description = "value of the ec2 instance private dns"
  value       = aws_instance.ec2_instance.private_dns

}

output "ec2_instance_public_dns" {
  description = "value of the ec2 instance public dns"
  value       = aws_instance.ec2_instance.public_dns

}

