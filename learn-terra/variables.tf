variable "instance_name" {
    description = "value of the instance name"
    type = string
    default = "max_server_tera"
  
}


variable "instance_type" {
    description = "value of the instance type"
    type = string
    default = "t2.micro"
  
}

variable "ami" {
    description = "value of the ami"
    type = string
    default = "ami-0c55b159cbfafe1f0"   
  
}

variable "aws_region" {
    description = "value of the aws region"
    type = string
    default = "eu-west-1"
  
}