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
  providers = {
    
  }
   
}

module "security_groups" {
  source = "./module/security-groups"
  vpc_id = module.networking.vpc_id
  vpc_cidr_block = module.networking.vpc_cidr_block
}

module "compute" {
  source = "./module/compute"
  public_security_group_id = module.security_groups.public_security_group_id
  private_security_group_id = module.security_groups.private_security_group_id  
  public_subnet_id = module.networking.public_subnet_id
  private_subnet_id = module.networking.private_subnet_id
}

module "notifications" {
  source = "./module/notifications"
  # project_tag = var.project_tag
  # environment_name = var.environment_name
  # department = var.department
  # notification_email = var.notification_email
}