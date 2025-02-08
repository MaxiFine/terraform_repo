output "instance_ids" {
  description = "The IDs of the created EC2 instances"
  value       = aws_instance.example[*].id
}

output "instance_public_ips" {
  description = "The public IP addresses of the created EC2 instances"
  value       = aws_instance.example[*].public_ip
}