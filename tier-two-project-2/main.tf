# Terraform Provider definition
# Define the provider within Terraform
# VPC NETWORK CONFIGS
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

#Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}


module "vpc" {
  source = "./vpc"
}

module "security_group" {
  source = "./security-group"
  db_password = var.db_password
  
}

module "alb" {
  source = "./alb"
  
}

module "ec2" {
  source = "./ec2"
  
}
