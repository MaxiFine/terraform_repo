variable "vpc_id" {
  description = "The ID of the VPC where the security groups will be created"
  type        = string

}

variable "aws_region" {
  description = "The AWS region where the resources will be deployed"
  type        = string
  default     = "eu-north-1"
}

variable "vpc_cidr_block" {
  description = "The CIDR block for the VPC"
  type        = string  
}