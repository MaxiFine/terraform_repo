variable "aws_region" {
    description = "AWS Regional Value"
    default = "eu-west-1"
  
}


variable "ami" {
    default = "ami-03fd334507439f4d1"
    description = "EU west 1 Image"
  
}

variable "instance_type" {
    default = "t2.micro"
 
}


variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

# Optionally, if you need to reference a public security group:
variable "public_sg_id" {
  description = "ID of the public security group"
  type        = string
}

variable "security_group_id" {
    description = "SEcurity group for Ec2"
    type = list(string)
}

