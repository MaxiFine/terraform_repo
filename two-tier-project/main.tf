module "vpc" {
  source = "./vpc"
  vpc_cidr = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]
}

module "security_groups" {
  source = "./security_group"
  vpc_id = module.vpc.vpc_id
}

module "ec2" {
  source          = "./ec2"
  ami         = "ami-03fd334507439f4d1"
  instance_type  = "t2.micro"
  public_subnets = module.vpc.public_subnets
  security_group_id = module.security_groups.web_sg_id
#   instance_count = 2
#   instance_name  = module.ec2.instance_name
}

module "rds" {
  source = "./rds"
  private_subnets = module.vpc.private_subnets
}

module "alb" {
  source = "./alb"
  public_subnets = module.vpc.public_subnets
  vpc_id = module.vpc.vpc_id
}

module "asg" {
  source = "./asg"
  public_subnets = module.vpc.public_subnets
}

locals {
  dns_zone_id = ""
}

module "route53" {
  source  = "./route53"
  zone_id = local.dns_zone_id
}
