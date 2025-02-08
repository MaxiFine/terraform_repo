variable "aws_region" {
    description = "AWS Regional Value"
    default = "eu-west-1"
  
}


variable "ami" {
    default = "ami-03fd334507439f4d1"
    description = "EU west 1 Image"
  
}

variable "instance_type" {
    default = "t2.micro"
 
}