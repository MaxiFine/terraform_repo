provider "aws" {
  region = var.region
}

module "vpc" {
  source = "./modules/vpc"
  vpc_cidr = "10.0.0.0/16"
  public_subnet_cidr = "10.0.1.0/24"
  private_subnet_cidr = "10.0.2.0/24"
}

module "security_group" {
  source = "./modules/security_group"
  vpc_id = module.vpc.vpc_id
}

module "alb" {
  source = "./modules/alb"
  vpc_id = module.vpc.vpc_id
  public_subnet_id = module.vpc.public_subnet_id
  security_group_id = module.security_group.alb_security_group_id
}

module "rds" {
  source = "./modules/rds"
  vpc_id = module.vpc.vpc_id
  private_subnet_id = module.vpc.private_subnet_id
  security_group_id = module.security_group.rds_security_group_id
}