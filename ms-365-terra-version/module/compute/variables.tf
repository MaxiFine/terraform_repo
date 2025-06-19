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


variable "ProjectTag" {
  type        = string
  default     = "AWS-365"
  description = "Project tag applied to all resources"
}

variable "EnvironmentName" {
  type        = string
  default     = "dev"
  description = "Environment name (e.g., dev, prod)"
}

variable "BucketPath" {
  type        = string
  description = "Name of S3 bucket path for the environment"
  default = "https://s3.amazonaws.com/aws-365/cf-templates"
}

variable "Department" {
  type        = string
  default     = "Any"
}



variable "RegionTag" {
  type        = string
  default     = "Any"
}

# Add other variables similarly...
variable "CostCenter" {
  type    = string
  default = "Any"
}
