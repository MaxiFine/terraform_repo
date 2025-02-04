terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "eu-west-1"
}

resource "aws_instance" "terraform_eg" {
  # ami           = "ami-011899242bb902164" # Ubuntu 20.04 LTS // us-east-1
  ami           = "ami-03fd334507439f4d1" # Ubuntu 20.04 LTS // switching to eu-west-1
  instance_type = "t2.micro"
}
