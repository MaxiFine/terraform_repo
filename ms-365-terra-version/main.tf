terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=5.88.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "networking" {
  source = "./networking"
   
}

module "security_groups" {
  source = "./security-groups"
  vpc_id = module.networking.vpc_id
}