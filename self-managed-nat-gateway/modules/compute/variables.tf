variable "ami_id" {
  description = "AMI ID to use for EC2 instances."
  type        = string
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
}


variable "region" {
  description         = "AWS Region for the service."
  type                = string
  default             = "eu-central-1"
}

variable "nat_instance_ami_id" {
  description         = "AMI ID for NAT Instance."
  type                = string
}

variable "main_vpc_id" {
  description         = "ID For the VPC ID."
  type                = string
}

variable "main_cidr_block" {
  description         = "CIDR Block for Main VPC."
  type                = string
}

variable "public_cidr_blocks" {
  description        = "Public Subnet CIDR Blocks."
  type               = list(string)
}
 
variable "private_cidr_blocks" {
  description        = "Private Subnet CIDR Blocks"
  type               = list(string)
}

variable "public_subnet_ids" {
  description         = "IDs for the Public Subnets."
  type                = list(string)
}

variable "create_nat_testing_instances" {
  description         = "Flag to add NAT Testing Instances in Private Subnets."
  type                = bool
}

variable "private_subnet_ids" {
  description         = "IDs for the Private Subnets."
  type                = list(string)
}

variable "private_subnet_route_table_ids" {
  description         = "IDs for Route Tables within Private Subnets."
  type                = list(string)
}

variable "private_ips_for_ssh" {
  description         = "IP Addresss which will allow SSH Connections from outside of VPC."
  type                = list(string)
}

variable "ec2_key_name" {
  description         = "Keyname used for ssh access to EC2 instances."
  type                = string
}


