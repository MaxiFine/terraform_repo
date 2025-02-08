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
  source = "./first-tier/vpc"
}

module "aws_security_group" {
  source      = "./first-tier/security-group"
  db_password = var.db_password
  db_username = var.db_username
}

# module "security_group" {
#   # source = "./security-group"
#   source = "./first-tier/security-group"
#   db_password = var.db_password

# }

module "alb" {
  source            = "./first-tier/alb"
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  public_sg_id      = module.aws_security_group.public_sg_id
}

module "ec2" {
  source            = "./first-tier/ec2"
  ami               = module.ec2.variable.ami
  security_group_id = module.aws_security_group.public_sg_id
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  public_sg_id      = module.aws_security_group.public_sg_id
}
