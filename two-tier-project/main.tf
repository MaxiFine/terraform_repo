module "vpc" {
  source = "./modules/vpc"
  vpc_cidr = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]
}

module "security_groups" {
  source = "./modules/security_groups"
  vpc_id = module.vpc.vpc_id
}

module "ec2" {
  source          = "./modules/ec2"
  ami_id         = "ami-123456"
  instance_type  = "t2.micro"
  public_subnets = module.vpc.public_subnets
  security_group_id = module.security_groups.web_sg_id
  instance_count = 2
}

module "rds" {
  source = "./modules/rds"
  private_subnets = module.vpc.private_subnets
}

module "alb" {
  source = "./modules/alb"
  public_subnets = module.vpc.public_subnets
  vpc_id = module.vpc.vpc_id
}

module "asg" {
  source = "./modules/asg"
  public_subnets = module.vpc.public_subnets
}

module "route53" {
  source  = "./modules/route53"
  zone_id = local.dns_zone_id
}
