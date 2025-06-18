variable "aws_region" {
  description = "The AWS region where the resources will be deployed."
  type        = string
  default     = "eu-north-1"

}

variable "aws_region_short" {
  description = "The short name of the AWS region, used for naming conventions."
  type        = string
  default     = "eu-north-1"

}

variable "aws_vpc_cidr" {
  description = "value for the VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet"
  type        = string
  default     = "10.0.2.0/24"
}

