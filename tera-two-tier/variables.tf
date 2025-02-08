variable "region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "us-west-2"
}

variable "ami_id" {
  description = "The AMI ID to use for the EC2 instances"
  type        = string
  default     = "ami-03fd334507439f4d1" # Replace with your AMI ID
}

variable "instance_type" {
  description = "The instance type for the EC2 instances"
  type        = string
  default     = "t2.micro"
}

variable "availability_zones" {
  description = "List of availability zones to distribute the instances"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b"]
}

