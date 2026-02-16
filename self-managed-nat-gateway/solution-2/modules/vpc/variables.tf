data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}


locals {
  az = data.aws_availability_zones.available.names[*] # Select the first available AZ
}


variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.11.0.0/16"
}


variable "vpc_name" {
  description = "Custom VPC name"
  type = string
  default = "self-managed-nat-gateway-vpc"
}


variable "private_subnet_count" {
  default = 2
}


variable "public_subnet_count" {
  default = 2
}


locals {
  private_subnets = [
    for i in range(var.private_subnet_count) :
    cidrsubnet(var.vpc_cidr, 8, i)    # /24 = 16 + 8
  ]

  public_subnets = [
    for i in range(var.public_subnet_count) :
    cidrsubnet(var.vpc_cidr, 8, i + 100)  # offset to avoid overlap
  ]
}
