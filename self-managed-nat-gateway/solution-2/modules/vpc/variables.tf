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