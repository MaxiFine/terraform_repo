# variable "public_ami_id" {
#   description = "The AMI ID for the public instance"
#   type        = string
# }

variable "public_instance_type" {
  description = "The instance type for the public instance"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "The name of the key pair to use for the instance"
  type        = string
  default     = "mx-keypair"
}

variable "public_security_group_id" {
  description = "The ID of the public security group"
  type        = string

}
variable "aws_region" {
  description = "The AWS region where the resources will be deployed"
  type        = string
  default     = "eu-north-1"
}

variable "private_security_group_id" {
  description = "The ID of the private security group"
  type        = string
  
}

variable "public_subnet_id" {
  description = "The ID of the public subnet"
  type        = string
  
}

variable "private_subnet_id" {
  description = "The ID of the private subnet"
  type        = string
  
}

variable "aws_region" {
  description = "The AWS region where the resources are deployed"
  type        = string
  default     = "eu-north-1"
  
}