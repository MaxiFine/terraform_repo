terraform {

    backend "remote" {
        organization = "mx-devops-consults"
        workspaces {
            name = "terra-01"
        }
      
    }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = var.aws_region

}

resource "aws_instance" "app_server" {
  ami           = var.ami
  instance_type = var.instance_type
  tags = {
    Name = var.instance_name
  }

}

