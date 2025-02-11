variable "AWS_SECRET_KEY" {
  description = "AWS Secret Key"
  type        = string
  sensitive   = true
  
}


variable "AWS_ACCESS_KEY" {
  description = "AWS Access Key"
  type        = string
  sensitive   = true
  
}

variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "eu-west-1"  
}

variable "amis" {
    description = "Map of AMIs by region"
    type        = map(string)
    default     = {
        eu-west-1 = "ami-0d1cd67c26f5f1dc1"
        us-east-1 = "ami-03fd334507439f4d1"
        us-west-1 = "ami-0f40c8f97004632f9"
    }
  
}

variable "PATH_TO_PRIVATE_KEY" {
    default = "levelup_key.pub"
  
}

variable "INSTANCE_USERNAME" {
    default = "ubuntu"
  
}