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
  source = "./module/networking"
   
}

module "security_groups" {
  source = "./module/security-groups"
  vpc_id = module.networking.vpc_id
}

module "compute" {
  source = "./module/compute"
  public_security_group_id = module.security_groups.public_security_group_id
  private_security_group_id = module.security_groups.private_security_group_id  
  public_subnet_id = module.networking.public_subnet_id
  private_subnet_id = module.networking.private_subnet_id
}